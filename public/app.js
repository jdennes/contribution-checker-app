(function (checker, $) {

  var renderResults, renderError;

  function setupRenderers() {
    if ($("#err-template").length) {
      renderError = Handlebars.compile($("#err-template").html());
    }
    if ($("#err-template").length) {
      renderResults = Handlebars.compile($("#results-template").html());
    }
  }

  function setupEventHandlers() {
    $(".form").submit(function() { return false; });
    $(".form input").keypress(function(e) {
      if (e.which == 13) { // Capture when "Enter" is pressed
        check();
      }
    });
    $(".js-check-commit").click(function(e) {
      $(".js-check-commit").attr("disabled", "");
      $(".form input").val($(this).attr("data-commit-url"));
      check();
      return false;
    });
    $(".js-show-more-commits").click(function(e) {
      $("#recent-commits ul li.hide").removeClass("hide");
      $(this).closest("li").remove();
      return false;
    });
  }

  function check() {
    $(".alert").hide();
    $("#results").hide();
    $("input").attr("disabled", "");
    $("#waiting").show();
    var commit_url = $("input[name=url]").val();
    $.ajax({
      type: "POST", url: "/", data: "url=" + commit_url, dataType: "json",
      success: function(data) {
        if (data.error_message) {
          $("#err").html(renderError(data)).show();
        } else {
          data.commit_url = commit_url;
          $("#results").html(renderResults(data)).show();
        }
      },
      error: function(xhr, status, error) {
        var data = { error_message: "Sorry, something went horribly wrong." };
        $("#err").html(renderError(data)).show();
      },
      complete: function() {
        $("#waiting").hide();
        $("input").removeAttr("disabled");
        $(".js-check-commit").removeAttr("disabled");
      }
    });
  }

  function ready(data) {
    setupRenderers();
    setupEventHandlers();
  }

  ready();

})(window.checker = window.checker || {}, jQuery);
