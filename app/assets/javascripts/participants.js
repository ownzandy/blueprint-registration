function delete_participant(id, selector) {
	$('#' + selector).fadeOut()
	$.ajax({ 
        type: "DELETE", 
        url: '/participants/' + id,  
        dataType: "JSON",
    });
}

function update_status(selector) {
	document.getElementById(selector).style.color = "green" 
}

