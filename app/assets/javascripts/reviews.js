$(function(){
  $("a.load_comments").on("click", function(e){

    // MANUAL
    // $.ajax({
    //   method: 'GET',
    //   url: this.href,
    // }).success(function(resp){
    //   $('div.comments').html(resp)
    // }

    // HTML
    // $.get(this.href).success(function(resp){
    //   $(div.comments).html(resp)
    // })

    // JSON
    $.get(this.href).success(function(json){
      var $ol = $("div.comments ol")
      $ol.html("")
      json.forEach(function(comment){
        $ol.append("<li>" + comment.content + "</li>");
      })
    })

    // RAILS
    // $.ajax({
    //   url: this.href,
    //   dataType: 'script'
    // })

    e.preventDefault();
  })
})
