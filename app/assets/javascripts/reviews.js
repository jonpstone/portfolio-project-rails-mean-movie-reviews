$(function(){
  $("a.load_comments").on("click", function(e){
    $.get(this.href).success(function(json){
      var $ul = $("div.comments ul")
      $ul.html("")
      json.forEach(function(comment){
        $ul.append("<li>" + comment.content + "</li>");
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
      success: function(r){
        $("#comment_content").val("");
        var $ul = $("div.comments ul");
        $ul.append(r + "<br />");
      }
    });
    e.preventDefault();
  })
});

var btnText;
$(function(){
  $('form').each(function(){
    var $that = $(this);
      $(this).submit(function(){
        var submitButton = $that.find("input[type='submit']");
        btnText = $(submitButton).attr("value");

        $.ajax({
          timeout: 2000,
          error: function(){
            alert("Comment failed to post...");
            $that.find("input[type='submit']").removeAttr('disabled');
          },
          success: function(r){
            $that.find("input[type='submit']").attr("value", btnText);
            $that.find("input[type='submit']").removeAttr('disabled');
          },
        })
      return false;
    })
  });
})
