#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class PostsController < ApplicationController
  before_filter :authenticate_user!, :except => :show
  respond_to :html
  respond_to :mobile
  respond_to :json
  def show
    if user_signed_in?
      show_authenticated
    else
      show_unauthenticated
    end
  end

  def show_authenticated
    @post = current_user.find_visible_post_by_id params[:id]
    if @post

      # mark corresponding notification as read
      if notification = Notification.where(:recipient_id => current_user.id, :target_id => @post.id).first
        notification.unread = false
        notification.save
      end

      respond_with @post
    else
      Rails.logger.info(:event => :link_to_nonexistent_post, :ref => request.env['HTTP_REFERER'], :user_id => current_user.id, :post_id => params[:id])
      flash[:error] = I18n.t('posts.show.not_found')
      redirect_to :back
    end
  end

  def show_unauthenticated
    if params[:guid].to_s.length <= 8
      @post = Post.where(:id => params[:guid], :public => true).includes(:author, :comments => :author).first
    else
      @post = Post.where(:guid => params[:guid], :public => true).includes(:author, :comments => :author).first
    end

    if @post
      @landing_page = true
      @person = @post.author
      if @person.owner_id
        I18n.locale = @person.owner.language

        respond_to do |format|
          format.all{ render "publics/#{@post.class.to_s.underscore}", :layout => 'application'}
          format.xml{ render :xml => @post.to_diaspora_xml }
        end
      else
        flash[:error] = I18n.t('posts.show.not_found')
        redirect_to root_url
      end
    else
      flash[:error] = I18n.t('posts.show.not_found')
      redirect_to root_url
    end
  end

  def destroy
    @post = current_user.posts.where(:id => params[:id]).first
    if @post
      current_user.retract(@post)
      respond_to do |format|
        format.js {render 'destroy'}
        format.all {redirect_to root_url}
      end
    else
      Rails.logger.info "event=post_destroy status=failure user=#{current_user.diaspora_handle} reason='User does not own post'"
      render :nothing => true, :status => 404
    end
  end
end
