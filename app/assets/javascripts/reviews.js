$(function(){
  $("a.load_comments").on("click", function(e){
    $.ajax({
      method: 'GET',
      url: this.href,
    }).done(function(resp){
      $('div.comments').html(resp)
    }
    e.preventDefault();
  })
})
