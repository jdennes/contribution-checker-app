(function (checker, $) {

  var renderResults, renderError;

  function setupRenderers() {
    renderError = Handlebars.compile($("#err-template").html());
    renderResults = Handlebars.compile($("#results-template").html());
  }

  function setupEventHandlers() {
    $(".form").submit(function() { return false; });
    $(".form input").keypress(function(e) {
      if (e.which == 13) { // Capture when "Enter" is pressed
        check();
      }
    });
    $("#recent-commits ul li.commit a").click(function(e) {
      $(".form input").val($(this).attr("data-commit-url"));
      check();
      return false;
    });
    $("#show-more-commits").click(function(e) {
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
      }
    });
  }

  function ready(data) {
    setupRenderers();
    setupEventHandlers();
  }

  ready();

})(window.checker = window.checker || {}, jQuery);
