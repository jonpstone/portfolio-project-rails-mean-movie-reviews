$(function(){
  $("a.show_reviews").on("click", function(e){
    $.get(this.href).success(function(json){
      var $ul = $("div.movies ul")
      $ul.html("")
      json.forEach(function(movie){
        var length = 350;
        var narrative = movie.content;
        var trunc = narrative.substring(0, length);
        $ul.append("<li>" + trunc + "..." + "</li><br>");
      })
    })
    e.preventDefault();
  })
})
