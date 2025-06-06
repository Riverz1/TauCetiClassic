
/datum/admins/proc/player_panel_new()//The new one
	if (!usr.client.holder)
		return
	var/dat = "<html><head><title>Admin Player Panel</title></head>"

	//javascript, the part that does most of the work~
	dat += {"

		<head>
			<meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
			<script type='text/javascript'>

				var locked_tabs = new Array();

				function updateSearch(){


					var filter_text = document.getElementById('filter');
					var filter = filter_text.value.toLowerCase();

					if(complete_list != null && complete_list != ""){
						var mtbl = document.getElementById("maintable_data_archive");
						mtbl.innerHTML = complete_list;
					}

					if(filter.value == ""){
						return;
					}else{

						var maintable_data = document.getElementById('maintable_data');
						var ltr = maintable_data.getElementsByTagName("tr");
						for ( var i = 0; i < ltr.length; ++i )
						{
							try{
								var tr = ltr\[i\];
								if(tr.getAttribute("id").indexOf("data") != 0){
									continue;
								}
								var ltd = tr.getElementsByTagName("td");
								var td = ltd\[0\];
								var lsearch = td.getElementsByTagName("b");
								var search = lsearch\[0\];
								//var inner_span = li.getElementsByTagName("span")\[1\] //Should only ever contain one element.
								//document.write("<p>"+search.innerText+"<br>"+filter+"<br>"+search.innerText.indexOf(filter))
								if ( search.innerText.toLowerCase().indexOf(filter) == -1 )
								{
									//document.write("a");
									//ltr.removeChild(tr);
									td.innerHTML = "";
									i--;
								}
							}catch(err) {   }
						}
					}

					var count = 0;
					var index = -1;
					var debug = document.getElementById("debug");

					locked_tabs = new Array();

				}

				function expand(id,job,name,real_name,image,key,ip,antagonist,ref){

					clearAll();

					var span = document.getElementById(id);

					body = "<table><tr><td>";

					body += "</td><td align='center'>";

					body += "<font size='2'><b>"+job+" "+name+"</b><br><b>Real name "+real_name+"</b><br><b>Played by "+key+" </b></font>"

					body += "</td><td align='center'>";

					body += "<a href='byond://?src=\ref[src];adminplayeropts="+ref+"'>PP</a> - "
					body += "<a href='byond://?src=\ref[src];notes=show;mob="+ref+"'>N</a> - "
					body += "<a href='byond://?_src_=vars;Vars="+ref+"'>VV</a> - "
					body += "<a href='byond://?src=\ref[src];traitor="+ref+"'>TP</a> - "
					body += "<a href='byond://?src=\ref[usr];priv_msg=\ref"+ref+"'>PM</a> - "
					body += "<a href='byond://?src=\ref[src];subtlemessage="+ref+"'>SM</a> - "
					body += "<a href='byond://?src=\ref[src];adminplayerobservejump="+ref+"'>JMP</a><br>"
					if(antagonist > 0)
						body += "<font size='2'><a class='red' href='byond://?src=\ref[src];check_antagonist=1'><b>Antagonist</b></a></font>";

					body += "</td></tr></table>";


					span.innerHTML = body
				}

				function clearAll(){
					var spans = document.getElementsByTagName('span');
					for(var i = 0; i < spans.length; i++){
						var span = spans\[i\];

						var id = span.getAttribute("id");

						if(!(id.indexOf("item")==0))
							continue;

						var pass = 1;

						for(var j = 0; j < locked_tabs.length; j++){
							if(locked_tabs\[j\]==id){
								pass = 0;
								break;
							}
						}

						if(pass != 1)
							continue;




						span.innerHTML = "";
					}
				}

				function addToLocked(id,link_id,notice_span_id){
					var link = document.getElementById(link_id);
					var decision = link.getAttribute("name");
					if(decision == "1"){
						link.setAttribute("name","2");
					}else{
						link.setAttribute("name","1");
						removeFromLocked(id,link_id,notice_span_id);
						return;
					}

					var pass = 1;
					for(var j = 0; j < locked_tabs.length; j++){
						if(locked_tabs\[j\]==id){
							pass = 0;
							break;
						}
					}
					if(!pass)
						return;
					locked_tabs.push(id);
					var notice_span = document.getElementById(notice_span_id);
					notice_span.innerHTML = "<font color='red'>Locked</font> ";
					//link.setAttribute("onClick","attempt('"+id+"','"+link_id+"','"+notice_span_id+"');");
					//document.write("removeFromLocked('"+id+"','"+link_id+"','"+notice_span_id+"')");
					//document.write("aa - "+link.getAttribute("onClick"));
				}

				function attempt(ab){
					return ab;
				}

				function removeFromLocked(id,link_id,notice_span_id){
					//document.write("a");
					var index = 0;
					var pass = 0;
					for(var j = 0; j < locked_tabs.length; j++){
						if(locked_tabs\[j\]==id){
							pass = 1;
							index = j;
							break;
						}
					}
					if(!pass)
						return;
					locked_tabs\[index\] = "";
					var notice_span = document.getElementById(notice_span_id);
					notice_span.innerHTML = "";
					//var link = document.getElementById(link_id);
					//link.setAttribute("onClick","addToLocked('"+id+"','"+link_id+"','"+notice_span_id+"')");
				}

				function selectTextField(){
					var filter_text = document.getElementById('filter');
					filter_text.focus();
					filter_text.select();
				}

			</script>
			[get_browse_zoom_style(usr.client)]
		</head>


	"}

	//body tag start + onload and onkeypress (onkeyup) javascript event calls
	dat += "<body onload='selectTextField(); updateSearch();' onkeyup='updateSearch();'>"

	//title + search bar
	dat += {"

		<table width='560' align='center' cellspacing='0' cellpadding='5' id='maintable'>
			<tr id='title_tr'>
				<td align='center'>
					<font size='5'><b>Player panel</b></font><br>
					Hover over a line to see more information - <a href='byond://?src=\ref[src];check_antagonist=1'>Check antagonists</a>
					<p>
				</td>
			</tr>
			<tr id='search_tr'>
				<td align='center'>
					<b>Search:</b> <input type='text' id='filter' value='' style='width:300px;'>
				</td>
			</tr>
	</table>

	"}

	//player table header
	dat += {"
		<span id='maintable_data_archive'>
		<table width='560' align='center' cellspacing='0' cellpadding='5' id='maintable_data'>"}

	var/list/mobs = sortmobs()
	var/i = 1
	for(var/mob/M as anything in mobs)
		if(M.ckey)

			var/color = "#e6e6e6"
			if(i%2 == 0)
				color = "#f2f2f2"
			var/is_antagonist = is_special_character(M)

			var/M_job = ""

			if(isliving(M))

				if(iscarbon(M)) //Carbon stuff
					if(ishuman(M))
						M_job = M.job
					else if(isslime(M))
						M_job = "slime"
					else if(ismonkey(M))
						M_job = "Monkey"
					else if(isxeno(M)) //aliens
						if(isxenolarva(M))
							M_job = "Alien larva"
						else if(isfacehugger(M))
							M_job = "Alien facehugger"
						else
							M_job = "Alien"
					else
						M_job = "Carbon-based"

				else if(issilicon(M)) //silicon
					if(isAI(M))
						M_job = "AI"
					else if(ispAI(M))
						M_job = "pAI"
					else if(isrobot(M))
						M_job = "Cyborg"
					else
						M_job = "Silicon-based"

				else if(isanimal(M)) //simple animals
					if(iscorgi(M))
						M_job = "Corgi"
					else
						M_job = "Animal"

				else
					M_job = "Living"

			else if(isnewplayer(M))
				M_job = "New player"

			else if(isobserver(M))
				M_job = "Ghost"

			M_job = replacetext(M_job, "'", "")
			M_job = replacetext(M_job, "\"", "")
			M_job = replacetext(M_job, "\\", "")

			var/M_name = M.name
			M_name = replacetext(M_name, "'", "")
			M_name = replacetext(M_name, "\"", "")
			M_name = replacetext(M_name, "\\", "")
			var/M_rname = M.real_name
			M_rname = replacetext(M_rname, "'", "")
			M_rname = replacetext(M_rname, "\"", "")
			M_rname = replacetext(M_rname, "\\", "")

			var/M_key = M.key
			M_key = replacetext(M_key, "'", "")
			M_key = replacetext(M_key, "\"", "")
			M_key = replacetext(M_key, "\\", "")

			//output for each mob
			dat += {"

				<tr id='data[i]' name='[i]' onClick="addToLocked('item[i]','data[i]','notice_span[i]')">
					<td align='center' bgcolor='[color]'>
						<span id='notice_span[i]'></span>
						<a id='link[i]'
						onmouseover='expand("item[i]","[M_job]","[M_name]","[M_rname]","--unused--","[M_key]","[M.lastKnownIP]",[is_antagonist],"\ref[M]")'
						>
						<span id='search[i]'><b>[M_name] - [M_rname] - [M_key] ([M_job])</b></span>
						</a>
						<br><span id='item[i]'></span>
					</td>
				</tr>

			"}

			i++


	//player table ending
	dat += {"
		</table>
		</span>

		<script type='text/javascript'>
			var maintable = document.getElementById("maintable_data_archive");
			var complete_list = maintable.innerHTML;
		</script>
	</body></html>
	"}

	usr << browse(dat, "window=players;[get_browse_size_parameter(usr.client, 600, 480)]")

//The old one
/datum/admins/proc/player_panel_old()
	if (!usr.client.holder)
		return
	var/dat
	dat += "<table border=1 cellspacing=5><B><tr><th>Name</th><th>Real Name</th><th>Assigned Job</th><th>Key</th><th>Options</th><th>PM</th><th>Traitor?</th></tr></B>"
	//add <th>IP:</th> to this if wanting to add back in IP checking
	//add <td>(IP: [M.lastKnownIP])</td> if you want to know their ip to the lists below
	var/list/mobs = sortmobs()

	for(var/mob/M as anything in mobs)
		if(!M.ckey) continue

		dat += "<tr><td>[M.name]</td>"
		if(isAI(M))
			dat += "<td>AI</td>"
		else if(isrobot(M))
			dat += "<td>Cyborg</td>"
		else if(ishuman(M))
			dat += "<td>[M.real_name]</td>"
		else if(ispAI(M))
			dat += "<td>pAI</td>"
		else if(isnewplayer(M))
			dat += "<td>New Player</td>"
		else if(isobserver(M))
			dat += "<td>Ghost</td>"
		else if(ismonkey(M))
			dat += "<td>Monkey</td>"
		else if(isxeno(M))
			dat += "<td>Alien</td>"
		else if(isessence(M))
			dat += "<td>Changelling Essence</td>"
		else
			dat += "<td>Unknown</td>"


		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(H.mind && H.mind.assigned_role)
				dat += "<td>[H.mind.assigned_role]</td>"
		else
			dat += "<td>NA</td>"


		dat += {"<td>[(M.client ? "[M.client]" : "No client")]</td>
		<td align=center><A href='byond://?src=\ref[src];adminplayeropts=\ref[M]'>X</A></td>
		<td align=center><A href='byond://?src=\ref[usr];priv_msg=\ref[M]'>PM</A></td>
		"}
		switch(is_special_character(M))
			if(0)
				dat += {"<td align=center><A href='byond://?src=\ref[src];traitor=\ref[M]'>Traitor?</A></td>"}
			if(1)
				dat += {"<td align=center><A class='red' href='byond://?src=\ref[src];traitor=\ref[M]'>Traitor?</A></td>"}
			if(2)
				dat += {"<td align=center><A class='red' href='byond://?src=\ref[src];traitor=\ref[M]'><b>Traitor?</b></A></td>"}

	dat += "</table>"

	var/datum/browser/popup = new(usr, "players", "Player Menu", 640, 480)
	popup.set_content(dat)
	popup.open()

/datum/admins/proc/check_antagonists()
	if (SSticker && SSticker.current_state >= GAME_STATE_PLAYING)
		var/dat = "<h1><B>Round Status</B></h1>"
		dat += "Current Game Mode: <B>[SSticker.mode.name]</B><BR>"
		dat += "Round Duration: <B>[round(world.time / 36000)]:[add_zero("[world.time / 600 % 60]", 2)]:[add_zero("[world.time / 10 % 60]", 2)]</B><BR>"
		dat += "<B>Emergency shuttle</B><BR>"
		if (!SSshuttle.online)
			dat += "<a href='byond://?src=\ref[src];call_shuttle=1'>Call Shuttle</a><br>"
		else
			switch(SSshuttle.location)
				if(0)
					dat += "ETA: <a href='byond://?src=\ref[src];edit_shuttle_time=1'>[shuttleeta2text()]</a><BR>"
					dat += "<a href='byond://?src=\ref[src];call_shuttle=2'>Send Back</a><br>"
				if(1)
					dat += "ETA: <a href='byond://?src=\ref[src];edit_shuttle_time=1'>[shuttleeta2text()]</a><BR>"
		dat += "<a href='byond://?src=\ref[src];delay_round_end=1'>[SSticker.admin_delayed ? "End Round Normally" : "Delay Round End"]</a><br>"

		dat += SSticker.mode.AdminPanelEntry()

		dat += "<h3><b>Factions</b></h3>"
		if(SSticker.mode.factions.len)
			for(var/datum/faction/F in SSticker.mode.factions)
				dat += F.AdminPanelEntry(src)
				dat += "<hr>"
		else
			dat += "<i>No factions are currently active.</i>"
		dat += "<h3>Other Roles</h3>"
		if(SSticker.mode.orphaned_roles.len)
			for(var/datum/role/R in SSticker.mode.orphaned_roles)
				dat += R.AdminPanelEntry(TRUE, src)//show logos
				dat += "<br>"
		else
			dat += "<i>No orphaned roles are currently active.</i>"
		dat += "<BR><BR><BR><a href='byond://?src=\ref[src];check_antagonist=1'>Refresh</a>"

		var/datum/browser/popup = new(usr, "roundstatus", "Round Status", 700, 700)
		popup.set_content(dat)
		popup.open()
	else
		tgui_alert(usr, "The game hasn't started yet!")
