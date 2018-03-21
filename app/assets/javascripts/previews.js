function sortData(a, b){
  if (a.year < b.year) {
    return 1;
  }
  if (a.year > b.year) {
    return -1;
  }
  return 0;
}

$(function(){
  $("a.show_reviews").on("click", function(e){
    e.preventDefault();
    $("a.show_reviews").hide();

    $.get(this.href).success(function(json){
      var $ul = $("div.movies ul");
      $ul.html("");
      var sortedData = json.sort(sortData);
      sortedData.forEach(function(movie){
        var narrative = movie.content;
        var trunc = narrative.substring(0, 500);
        var url = movie.writer_id + "/reviews/" + movie.id;
        var readMore = "Read more";

        $ul.append(
          `<li style='display: inline-block; vertical-align: top;'>
          <a href='${url}'><img src='${movie.image.url}'
            width='100'
            height='140'
            style='float: left; padding-right: 20px; padding-bottom: 20px'>
          </a>
          <a href='${url}'>
          <h4 class='title' style='margin-top: -0.05%;'>
            ${movie.title} | ${movie.year}
          </h4></a>
          <p style='margin-top: 2%;'>
            ${trunc}...<strong>${readMore.link(url)}</strong>
          </p></li>`
        );
      });
    });
  });
});
