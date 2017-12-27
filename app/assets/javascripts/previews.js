// $(function(){
//   $("a.show_reviews").on("click", function(e){
//     $.get(this.href).success(function(json){
//       var $p = $("div.movies p");
//       $p.html("");
//       json.forEach(function(movie){
//         var title = movie.title;
//         var narrative = movie.content;
//         var trunc = narrative.substring(0, 350);
//         var writer = movie.writer_id;
//         var review = movie.id;
//         var linkText = "Read more";
//         var url = writer + "/reviews/" + review
//         $p.append(
//           "<li>" + "<h4 class='title'>" + title + "</h4>" +
//           trunc + "..." + "<strong>" + linkText.link(url) + "</strong></li><br>"
//         );
//       });
//     });
//     e.preventDefault();
//   });
// });

$(function(){
  $("a.show_reviews").on("click", function(e){
    $.get(this.href).success(function(json){

      var $img = $("div.image");
      var $title = $("div.movie_title");
      var $para = $("div.movies p");
      var $prev = $("div.prev");
      var $next = $("div.next");

      var imgSrc = json[0].image.url;
      var firstMovieTitle = json[0].title;
      var firstMovieContent = json[0].content.substring(0, 500);
      var linkText = "Read more";
      var url = json[0].writer_id + "/reviews/1";

      $img.html("");
      $img.append(
        '<img src= "' + imgSrc + '" style="float: left; padding-right: 20px; padding-bottom: 20px">'
      );
      $title.html("");
      $title.append(
        "<h3 class='title'>" + firstMovieTitle + "</h3>"
      );
      $para.html("");
      $para.append(
        firstMovieContent + "... " + "<strong>" + linkText.link(url) + "</strong></li><br>"
      );
      $prev.html("");
      $prev.append(
        '<img src="/assets/prev.png "width="100" height="100">'
      );
      $next.html("");
      $next.append(
        '<img src="/assets/next.png "width="100" height="100">'
      );
    });
    e.preventDefault();
  });
});
