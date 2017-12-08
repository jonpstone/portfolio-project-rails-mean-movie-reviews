$(function(){
  $("a.load_comments").on("click", function(e){
    $.ajax({
      method: 'GET',
      url: this.href,
    }).done(function(data){
      console.log(data)
    }
    e.preventDefault();
  })
})
