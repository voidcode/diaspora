#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class UsersController < ApplicationController
  require File.join(Rails.root, 'lib/diaspora/ostatus_builder')
  require File.join(Rails.root, 'lib/diaspora/exporter')
  require File.join(Rails.root, 'lib/collect_user_photos')

  before_filter :authenticate_user!, :except => [:new, :create, :public]

  respond_to :html

  def edit
    @email_prefs = Hash.new(true)
    user.user_preferences.each do |pref|
      @email_prefs[pref.email_type] = false
    end
  end

  def update
    password_changed = false
    if u = params[:user]

      u.delete(:password) if u[:password].blank?
      u.delete(:password_confirmation) if u[:password].blank? and u[:password_confirmation].blank?
      u.delete(:language) if u[:language].blank?

      # change email notifications
      if u[:email_preferences]
        user.update_user_preferences(u[:email_preferences])
        flash[:notice] = I18n.t 'users.update.email_notifications_changed'
      # change password
      elsif u[:current_password] && u[:password] && u[:password_confirmation]
        if user.update_with_password(u)
          password_changed = true
          flash[:notice] = I18n.t 'users.update.password_changed'
        else
          flash[:error] = I18n.t 'users.update.password_not_changed'
        end
      elsif u[:language]
        if user.update_attributes(:language => u[:language])
          I18n.locale = user.language
          flash[:notice] = I18n.t 'users.update.language_changed'
        else
          flash[:error] = I18n.t 'users.update.language_not_changed'
        end
      end
    end

    respond_to do |format|
      format.js   { render :nothing => true, :status => 204 }
      format.all  { redirect_to password_changed ? new_user_session_path : edit_user_path }
    end
  end

  def destroy
    Resque.enqueue(Job::DeleteAccount, current_user.id)
    current_user.lock_access!
    sign_out current_user
    flash[:notice] = I18n.t 'users.destroy'
    redirect_to root_path
  end

  def public
    if user = User.find_by_username(params[:username])
      respond_to do |format|
        format.atom do
          posts = StatusMessage.where(:author_id => user.person.id, :public => true).order('created_at DESC').limit(25)
          director = Diaspora::Director.new
          ostatus_builder = Diaspora::OstatusBuilder.new(user, posts)
          render :xml => director.build(ostatus_builder), :content_type => 'application/atom+xml'
        end

        format.html { redirect_to person_path(user.person.id) }
      end
    else
      redirect_to root_url, :error => I18n.t('users.public.does_not_exist', :username => params[:username])
    end
  end

  def getting_started
    if step == 4 && friends.empty?
      flash[:notice] = I18n.t('users.getting_started.could_not_find_anyone')
      getting_started_completed
    else
      render "users/getting_started"
    end
  end

  def getting_started_completed
    current_user.update_attributes(:getting_started => false)
    redirect_to root_path
  end

  def export
    exporter = Diaspora::Exporter.new(Diaspora::Exporters::XML)
    send_data exporter.execute(current_user), :filename => "#{current_user.username}_diaspora_data.xml", :type => :xml
  end

  def export_photos
    tar_path = PhotoMover::move_photos(current_user)
    send_data( File.open(tar_path).read, :filename => "#{current_user.id}.tar" )
  end

  #helper methods
  def aspect
    request.path.include?('getting_started') ? :getting_started : :user_edit
  end

  def step
    @step ||= params[:step].to_i if((1..4) === params[:step].to_i)
    @step ||= 1
    @step +=1 if(@step == 3 && !AppConfig.configured_services.include?('facebook'))
    @step
  end

  def previous_step
    step > 1 ? step-1 : nil
  end

  def user
    @user ||= current_user
  end
  
  def person
    @person ||= user.person
  end

  def profile
    @profile ||= person.profile
  end

  def services
    @services ||= user.services
  end

  def friends
    if step == 4
      facebook = user.services.where(:type => "Services::Facebook").first
      @friends = facebook ? facebook.finder(:local => true) : []
    end
      @friends ||= []
      @friends
  end

  helper_method :previous_step, :aspect, :step, :user, :person, :profile, :services
end
