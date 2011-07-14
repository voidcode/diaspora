$(document).ready(function () {
	var autocompleteInput = $("#profile_tag_string");
  autocompleteInput.tipsy({trigger: 'focus', gravity: 'w'});

  autocompleteInput.autoSuggest("/tags", {
    selectedItemProp: "name",
    searchObjProps: "name",
    asHtmlID: "tags",
    neverSubmit: true,
    retriveLimit: 10,
    selectionLimit: 5,
    minChars: 2,
    keyDelay: 200,
    startText: '',
    limitText: Diaspora.widgets.i18n.t("tag_autocompleter.no_more_tags"),
    preFill: tagAutocompleteData
    });

  autocompleteInput.bind('keydown', function(evt){
    if(evt.keyCode == 13 || evt.keyCode == 9 || evt.keyCode == 32){
      if( $('li.as-result-item.active').length == 0 ){
        $('li.as-result-item').first().click();
      }
    }
  });
});