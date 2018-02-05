$(function (){
  $("#js-next").on("click", function() {
    var nextId = parseInt($("#js-next").attr("data-id")) + 1;
    $.get("/genres/" + nextId + ".json", function(data) {
      $(".title").text(data["genre_name"]);
      var $list = $(".list");
      $list.html("");
      data.reviews.forEach(function(movie){
        $list.append(
          `<a href='/reviews/${movie.id}'><img title='${movie.title}'
          id='gImage' width='200' height='300' style='margin-right: 2em;
          margin-bottom: 2em;' src='${movie.image.url}' alt='After earth'></a>`
        );
      });
      $("#js-next").attr("data-id", data["id"]);
      $("#js-prev").attr("data-id", data["id"]) + 1;
    });
  });

  $("#js-prev").on("click", function(){
    var prevId = parseInt($("#js-prev").attr("data-id")) - 1;
    $.get("/genres/" + prevId + ".json", function(data) {
      $(".title").text(data["genre_name"]);
      var $list = $(".list");
      $list.html("");
      data.reviews.forEach(function(movie){
        $list.append(
          `<a href='/reviews/${movie.id}'><img title='${movie.title}'
          id='gImage' width='200' height='300' style='margin-right: 2em;
          margin-bottom: 2em;' src='${movie.image.url}' alt='After earth'></a>`
        );
      });
      $("#js-prev").attr("data-id", data["id"]);
      $("#js-next").attr("data-id", data["id"]) - 1;
    });
  });
});
