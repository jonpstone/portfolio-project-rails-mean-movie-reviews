$(function(){
  $("a.load_comments").on("click", function(e){
    $.get(this.href).success(function(json){
      var $ol = $("div.comments ol")
      $ol.html("")
      json.forEach(function(comment){
        $ol.append("<li>" + comment.content + "</li>");
      })
    })
    e.preventDefault();
  })
})

$(function(){
  $("#new_comment").on("submit", function(e){
    $.ajax({
      type: ($("input[name='_method']").val() || this.method),
      url: this.action,
      data: $(this).serialize(),
      success: function(resp){
        $("#comment_content").val("");
        var $ol = $("div.comments ol");
        $ol.append(resp);
      }
    });
    e.preventDefault();
  })
});
