// From https://gist.github.com/thisisbrians/4699851

jQuery.fn.selectTimeZone = function() {
   var $el = $(this[0]); // our element

   year = new Date().getFullYear();
   var jan = new Date(year, 0, 1);
   var jul = new Date(year, 6, 1);
   var offsetFromGMT = String(-(Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset())/60));


   if (offsetFromGMT[0] != '-') {
      offsetFromGMT = '+' + offsetFromGMT; // if it's not negative, prepend a +
   }
   if (offsetFromGMT.length < 3) {
      offsetFromGMT = offsetFromGMT.substr(0, 1) + '0' + offsetFromGMT.substr(1); // add a leading zero if we need it
   }
   offsetFromGMT = '\\' + offsetFromGMT;

   var regEx = new RegExp(offsetFromGMT); // create a RegExp object with our pattern

   $('option', $el).each(function(index, option) { // loop through all the options in our element
     var $option = $(option); // cache a jQuery object for the option
     if($option.html().match(regEx)) { // check if our regex matches the html(text) inside the option
       $option.attr({selected: 'true'}); // select the option
       return false; // stop the loop—we're all done here
   }
 });
}
