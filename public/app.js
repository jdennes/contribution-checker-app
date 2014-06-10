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
        var commit_url = $("input[name=url]").val();
        $.ajax({
          type: "POST",
          url: "/",
          data: "url=" + commit_url,
          dataType: "json",
          success: function(data) {
            if (data.error_message) {
              $("#err").html(renderError(data));
              $("#err").show();
            } else {
              data.commit_url = commit_url;
              $("#results").html(renderResults(data));
              $("#results").show();
            }
          },
          error: function(xhr, status, error) {
          }
        });
      }
    });
  }

  ready();

})(window.checker = window.checker || {}, jQuery);
