function Comment(attr){
  this.content = attr.content;
}

$(function(){
  Comment.templateSource = $("#comment-template").html();
  Comment.template = Handlebars.compile(Comment.templateSource);
});

Comment.prototype.renderLI = function(){
  return Comment.template(this);
}

$(function(){
  $("#gap").hide();

  $("a.load_comments").on("click", function(e){
    $("a.load_comments").hide();
    $("#gap").show();
    $.get(this.href).success(function(json){
      var $ul = $("div.comments ul");
      $ul.html("");
      json.forEach(function(comment_list){
        $ul.append(`<li>${comment_list.content}</li><br>`);
      });
    });
    e.preventDefault();
  });

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
        var comment = new Comment(json);
        var commentLi = comment.renderLI();

        $("#comment_content").val("");
        $("div.comments ul").append(`<li>${commentLi}</li><br>`);
      }
    });
    e.preventDefault();
  });
});
