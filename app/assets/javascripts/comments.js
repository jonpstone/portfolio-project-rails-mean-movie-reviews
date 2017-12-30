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

  $("#new_comment").on("submit", function(e){
    $.ajax({
      type: ($("input[name='_method']").val() || this.method),
      url: this.action,
      data: $(this).serialize(),
      success: function(resp){
        $("#comment_content").val("");
        var $ul = $("div.comments ul");
        $ul.append(resp + "<br />");
      }
    });
    e.preventDefault();
  });

  $('form').each(function(e){
    var $that = $(this);
      $(this).submit(function(){
        $.ajax({
          error: function(){
            alert("Comment failed to post...");
            $that.find("input[type='submit']").removeAttr('disabled');
          },
          success: function(){
            $that.find("input[type='submit']").removeAttr('disabled');
          },
        });
      return false;
    });
  });
});
