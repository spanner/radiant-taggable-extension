var TagSuggester = Behavior.create({
  initialize: function() {
    var textbox = this.element;
    new Autocomplete(textbox, { 
      serviceUrl: '/admin/tags.json', 
      minChars: 2, 
      maxHeight: 400, 
      deferRequestBy: 500,
      multiple: true
    });
  }
});

Event.addBehavior({
  'input.toggle': Toggle.CheckboxBehavior({ onLoad: function(link) { if (!this.checked) Toggle.hide(this.toggleWrappers, this.effect); } }),
  'input.tagger': TagSuggester
});


