
$(function(){
  $("a.load_comments").on("click", function(e){
    $.get(this.href).success(function(json){
      var $ul = $("div.comments ul");
      $ul.html("");
      json.forEach(function(comment){
        $ul.append("<li>" + comment.content + "</li><br>");
      });
    });
    e.preventDefault();
  });

  // $("#new_comment").on("submit", function(e){
  //   $('#comment-button').removeAttr('data-disable-with');
  //   $.ajax({
  //     type: ($("input[name='_method']").val() || this.method),
  //     dataType: "json",
  //     url: this.action,
  //     data: $(this).serialize(),
  //     success: function(json){
  //       $("#comment_content").val("");
  //       $("div.comments ul").append("<li>" + json.content + "</li><br />");
  //     }
  //   });
  //   e.preventDefault();
  // });

  $("#new_comment").on("submit", function(e){
    $('#comment-button').removeAttr('data-disable-with');
    var $form = $(this);
    var action = $form.attr("action");
    var params = $form.serialize();

    $.ajax({
      url: action,
      data: params,
      dataType: "json",
      method: ($("input[name='_method']").val() || this.method),
      success: function(json){
        debugger
        $("#comment_content").val("");
        $("div.comments ul").append("<li>" + json.content + "</li><br />");
      }
    });
    e.preventDefault();
  });
});
