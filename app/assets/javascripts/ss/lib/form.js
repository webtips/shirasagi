this.SS_Form = (function () {
// Disable enter key[13]

// @example
//   SS_Form.disableEnterKey();
//   SS_Form.disableEnterKey('#item_subject');

// @param [String] selector
// @return [Boolean]
  function SS_Form() {
  }

  SS_Form.render = function () {
    $('.form-example-head').on('click', function() {
      var el = $(this);
      var name = el.attr('class').replace(/.* (example-.*?)( |$)/, '$1');
      var form = el.closest('.form-example');
      form.find(`.form-example-body.${name}`).slideToggle('fast');
    });
  };

  SS_Form.disableEnterKey = function (selector) {
    if (selector == null) {
      selector = null;
    }
    if (selector) {
      return $(selector).on('keypress', function (ev) {
        return ev.which !== 13;
      });
    } else {
      return $(document).on('keypress', 'input:not(.allow-submit)', function (ev) {
        return ev.which !== 13;
      });
    }
  };

  return SS_Form;

})();

// ---
// generated by coffee-script 1.9.2