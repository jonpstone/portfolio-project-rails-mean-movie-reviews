$(function(){
  $("a.show_reviews").on("click", function(e){
    $.get(this.href).success(function(json){
      var $ul = $("div.movies ul")
      $ul.html("")
      json.forEach(function(movie){
        var title = movie.title;
        var narrative = movie.content;
        var trunc = narrative.substring(0, 350);
        var writer = movie.writer_id;
        var review = movie.id;
        var linkText = "Read more";
        var url = writer + "/reviews/" + review
        $ul.append(
          "<li>" + "<h4 class='title'>" + title + "</h4>" +
          trunc + "..." + "<strong>" + linkText.link(url) + "</strong></li><br>"
        );
      })
    })
    e.preventDefault();
  })
});
