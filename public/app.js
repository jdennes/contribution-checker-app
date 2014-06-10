(function (checker, $) {

  var renderResults, renderError;

  function setupRenderers() {
    renderError = Handlebars.compile($("#err-template").html());
    renderResults = Handlebars.compile($("#results-template").html());
  }

  function ready(data) {
    setupRenderers();
    $(".form").submit(function() { return false; });
    $(".form input").keypress(function(e) {
      if(e.which == 13) {
        $(".alert").hide();
        $("#results").hide();
        $("input").attr("disabled", "");
        $("#waiting").show();
        var commit_url = $("input[name=url]").val();
        $.ajax({
          type: "POST",
          url: "/",
          data: "url=" + commit_url,
          dataType: "json",
          success: function(data) {
            if (data.error_message) {
              $("#err").html(renderError(data)).show();
            } else {
              data.commit_url = commit_url;
              $("#results").html(renderResults(data)).show();
            }
          },
          error: function(xhr, status, error) {
            var data = { error_message: "Something went horribly wrong..." };
            $("#err").html(renderError(data)).show();
          },
          complete: function() {
            $("#waiting").hide();
            $("input").removeAttr("disabled");
          }
        });
      }
    });
  }

  ready();

})(window.checker = window.checker || {}, jQuery);
