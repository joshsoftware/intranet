$.fn.alert = function (props) {
	if (typeof props.txt === 'undefined') return;
  if (typeof props.type === 'undefined') props.type = 'info';
  var ele = this[0];
  $(ele).html('<div id="alert" class="alert alert-'+props.type+'"><button type="button" class="close" data-dismiss="alert">&times;</button>'+props.txt+'</div>');
}
