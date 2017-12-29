$(function(){
  $("a.show_reviews").on("click", function(e){
    $.get(this.href).success(function(json){
      var $ul = $("div.movies ul");
      $ul.html("");
      json.forEach(function(movie){
        var title = movie.title;
        var narrative = movie.content;
        var trunc = narrative.substring(0, 500);
        var writer = movie.writer_id;
        var review = movie.id;
        var url = writer + "/reviews/" + review;
        var imgSrc = movie.image.url;
        debugger
        $ul.append(
          "<li style='display: inline-block; vertical-align: top;'>" +
          "<a href=" + url + ">" + '<img src= "' + imgSrc +
          '" "width="70" height="140" style="float: left; padding-right: 20px; padding-bottom: 20px">' + "</a>" +
          "<h4 class='title' style='margin-top: -0.05%;'>" + title + "</h4><p style='margin-top: 2%;'>" +
          trunc + "..." + "\n<strong>" + "Read more".link(url) + "</strong></p></li>"
        );
      });
    });
    e.preventDefault();
  });
});
