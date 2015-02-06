<cfcomponent name="PostMarkAPI" hint="I send messages using the Postmarkapp.com API">
	<cffunction name="sendMail" access="public" returntype="string" description="Assembles JSON packet and sends it to Postmarkapp">
		<!--- Recipient and subject are required parameters.  Also need their API key. --->
		<cfargument name="mailTo" required="yes" type="string" displayname="Recipient of the message" />
		<cfargument name="mailFrom" required="yes" type="string" displayname="Sender of the message" />
		<cfargument name="mailSubject" required="yes" type="string" displayname="Subject of the message" />
		<cfargument name="apiKey" required="yes" type="string" displayname="API key, or server token">
		<!--- CC recipients, text body and HTML body are all optional --->
		<cfargument name="mailReply" required="no" type="string" displayname="Reply-to Address (if applicable)" />
		<cfargument name="mailCc" required="no" type="string" displayname="CC recipients (if applicable)" />
		<cfargument name="mailHTML" required="no" type="string" displayname="HTML body of the message" />
		<cfargument name="mailTxt" required="no" type="string" displayname="Plain text body of the message" />
		<cfargument name="mailAttachment" required="no" type="string" displayname="Attachment (optional)" />
		<!---Need to escape strings for JSON --->
		<cfset var mailto = JSStringFormat(arguments.mailTo) />
		<cfset var mailFrom = JSStringFormat(arguments.mailFrom) />
		<cfset var mailSubject = JSStringFormat(arguments.mailSubject) />
		<cfset var mailCc = '' />
		<cfset var mailHTML = '' />
		<cfset var mailTxt = '' />
		<cfset var mailReply = '' />
		<cfif structKeyExists(arguments, "mailCc") AND arguments.mailCc NEQ "">
			<cfset mailCc = JSStringFormat(arguments.mailCc) />
		</cfif>
		<cfif structKeyExists(arguments, "mailHTML") AND arguments.mailHTML NEQ "">
			<cfset mailHTML = JSStringFormat(arguments.mailHTML) />
		</cfif>
		<cfif structKeyExists(arguments, "mailTxt") AND arguments.mailTxt NEQ "">
			<cfset mailTxt = JSStringFormat(arguments.mailTxt) />
		</cfif>
		<cfif structKeyExists(arguments, "mailReply") AND arguments.mailReply NEQ "">
			<cfset mailReply = JSStringFormat(arguments.mailReply) />
		</cfif>
		<!--- If a filename to attach is specified:
			1. Check that it exists
			2. Read as a binary file
			3. Convert to Base64
		--->
		<cfif structKeyExists(arguments,"mailAttachment") AND arguments.mailAttachment NEQ "">
			<cfif FileExists(arguments.mailAttachment)>
				<cfset attachmentFile = ToBase64(FileReadBinary(arguments.mailAttachment))>
				<!--- Split filename by Unix-style directory slashes. Set last piece as displayed attachment name --->
				<cfset attachmentName = ListLast(arguments.mailAttachment,"/")>
			</cfif>
		</cfif>
		<!--- Assemble the JSON packet to send to Postmarkapp --->
		<cfsavecontent variable="jsonPacket">
			<cfprocessingdirective suppressWhiteSpace="yes">
				<cfoutput>
				{
					"From" : "#mailFrom#",
					"To" : "#mailTo#",
					<cfif len(trim(mailCc))>"Cc" : "#mailCc#",</cfif>
					"Subject" : "#mailSubject#"
					<cfif len(trim(mailHTML))>, "HTMLBody" : "#mailHTML#"</cfif>
					<cfif len(trim(mailTxt))>, "TextBody" : "#mailTxt#"</cfif>
					<cfif len(trim(mailReply))>, "ReplyTo" : "#mailReply#"</cfif>
					<!--- If we specified a filename, and successfully read it above, specify it here, and send as a Base64 octet-stream --->
					<cfif IsDefined("attachmentName") AND IsDefined("attachmentFile")>, "Attachments" : [{ "Name": "#JSStringFormat(attachmentName)#", "Content": "#JSStringFormat(attachmentFile)#", "ContentType": "application/octet-stream" }]</cfif>
				}
				</cfoutput>
			</cfprocessingdirective>
		</cfsavecontent>
		<!--- Send the request to Postmarkapp --->
		<cfhttp url="http://api.postmarkapp.com/email" method="post">
			<cfhttpparam type="header" name="Accept" value="application/json" />
			<cfhttpparam type="header" name="Content-type" value="application/json" />
			<cfhttpparam type="header" name="X-Postmark-Server-Token" value="#arguments.apiKey#" />
			<cfhttpparam type="body" encoded="no" value="#jsonPacket#" />
		</cfhttp>
		<!--- Return the status code --->
		<cfreturn cfhttp.statusCode />
	</cffunction>
</cfcomponent>
