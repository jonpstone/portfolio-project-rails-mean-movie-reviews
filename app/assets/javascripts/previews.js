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
      var $para = $("div.movies p");
      var imgSrc = json[0].image.url;
      var firstMovieTitle = json[0].title;
      var firstMovieContent = json[0].content.substring(0, 500);

      $para.html("");
      $para.append(
        "<h4 class='title'>" + firstMovieTitle + "<h4>" + "\n" + firstMovieContent
      );
      $img.html("");
      $img.append(
        '<img src= "' + imgSrc + '" style="float: left; padding-right: 20px; padding-bottom: 20px">'
      );
    });
    e.preventDefault();
  });
});
