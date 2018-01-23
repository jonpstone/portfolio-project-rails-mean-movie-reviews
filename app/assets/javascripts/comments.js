function Comment(attr){
  this.content = attr.content;
}

Comment.ready = function(){
  Comment.templateSource = $("#comment-template").html();
  Comment.template = Handlebars.compile(Comment.templateSource);
}

Comment.formSubmit = function(e){
  e.preventDefault();
  $('#comment-button').removeAttr('data-disable-with');
  var $form = $(this);
  var action = $form.attr("action");
  var params = $form.serialize();
  $.ajax({
    url: action,
    data: params,
    dataType: "json",
    method: ($("input[name='_method']").val() || this.method),
    success: Comment.success
  });
}
Comment.success = function(json){
  var comment = new Comment(json);
  var commentLi = comment.renderLI();

  $("#comment_content").val("");
  $("div.comments ul").append(`<li>${commentLi}</li><br>`);
}

Comment.prototype.renderLI = function(){
  return Comment.template(this);
}

Comment.list = function(){
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
}

$(function(){
  Comment.ready();
  Comment.list();
  $("#gap").hide();
  $("form#new_comment").on("submit", Comment.formSubmit);
});
