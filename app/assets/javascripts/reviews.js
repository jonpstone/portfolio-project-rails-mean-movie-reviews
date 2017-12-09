$(function(){
  $("a.load_comments").on("click", function(e){
    // $.ajax({
    //   method: 'GET',
    //   url: this.href,
    // }).success(function(resp){
    //   $('div.comments').html(resp)
    // }
    e.preventDefault();
  })
})
