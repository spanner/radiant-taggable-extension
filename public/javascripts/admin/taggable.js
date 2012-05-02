/*
 *
 * http://stackoverflow.com/questions/4932193/how-to-extend-the-scriptaculous-autocompleter
 * Script provided by http://spoike.se/
 */
var JSONCompleter = Class.create(Ajax.Autocompleter, {

    initialize: function($super, id_search, id_list, url, options) {
        $super(id_search, id_list, url, options);
    },

    onComplete: function(response) {
        var text = response.responseText;
        if (text.isJSON()) {
            this.handleJSON(text.evalJSON());
        }
        // else do nothing
    },

    handleJSON: function(json) {
        var htmlStr = '<ul>';
        json.each(function(item) {
            htmlStr += '<li>';
            htmlStr += item;
            htmlStr += '</li>';
        });
        htmlStr += '</ul>';
        this.updateChoices(htmlStr);
    }

});

var TagSuggester = Behavior.create({
    initialize: function() {
        var textbox = this.element;
        new JSONCompleter(textbox, "autocomplete_choices", "/admin/tags.json", {
            paramName: 'query',
            tokens: [',', ';'], method: 'get',
            callback: includeTags
        });
        // We send the current content along with the toke to prevent resuggestion
        function includeTags(element, entry){
            return entry +=  "&content=" + encodeURIComponent(element.value);
        };
    }
});

Event.addBehavior({
    'input.toggle': Toggle.CheckboxBehavior({ onLoad: function(link) { if (!this.checked) Toggle.hide(this.toggleWrappers, this.effect); } }),
    'input.tagger': TagSuggester
});
