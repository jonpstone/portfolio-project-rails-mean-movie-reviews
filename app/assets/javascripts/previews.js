$(function(){
  $("a.show_reviews").on("click", function(e){
    $.get(this.href).success(function(json){
      var $ul = $("div.movies ul");
      $ul.html("");
      json.forEach(function(movie){
        var title = movie.title;
        var narrative = movie.content;
        var trunc = narrative.substring(0, 600);
        var writer = movie.writer_id;
        var review = movie.id;
        var url = writer + "/reviews/" + review;
        var imgSrc = movie.image.url;
        debugger
        $ul.append(
          "<li style='display: inline-block; vertical-align: top;'>" +
          '<img src= "' + imgSrc + '" "width="100" height="200 style="float: left; padding-right: 20px; padding-bottom: 20px">' +
          "<h4 class='title'>" + title + "</h4>" + trunc + "..." + "\n<strong>" + "Read more".link(url) + "</strong></p></li><br />"
        );
      });
    });
    e.preventDefault();
  });
});
