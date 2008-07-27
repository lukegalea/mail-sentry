/* Import plugin specific language pack */
tinyMCE.importPluginLanguagePack('advhr', 'en,de,sv,zh_cn,cs,fa,fr_ca,fr,pl,pt_br');

function TinyMCE_advhr_getControlHTML(control_name) {
    switch (control_name) {
        case "advhr":
            return '<img id="{$editor_id}_advhr" src="{$pluginurl}/images/advhr.gif" title="{$lang_insert_advhr_desc}" width="20" height="20" class="mceButtonNormal" onmouseover="tinyMCE.switchClass(this,\'mceButtonOver\');" onmouseout="tinyMCE.restoreClass(this);" onmousedown="tinyMCE.restoreAndSwitchClass(this,\'mceButtonDown\');" onclick="tinyMCE.execInstanceCommand(\'{$editor_id}\',\'mceAdvancedHr\');" />';
    }
    return "";
}

/**
 * Executes the mceAdvanceHr command.
 */
function TinyMCE_advhr_execCommand(editor_id, element, command, user_interface, value) {
    // Handle commands
    switch (command) {
        case "mceAdvancedHr":
            var template = new Array();
            template['file']   = '../../plugins/advhr/rule.htm'; // Relative to theme
            template['width']  = 270;
            template['height'] = 180;
            var size = "", width = "", noshade = "";
            if (tinyMCE.selectedElement != null && tinyMCE.selectedElement.nodeName.toLowerCase() == "hr"){
                tinyMCE.hrElement = tinyMCE.selectedElement;
                if (tinyMCE.hrElement) {
                    size    = tinyMCE.hrElement.getAttribute('size') ? tinyMCE.hrElement.getAttribute('size') : "";
                    width   = tinyMCE.hrElement.getAttribute('width') ? tinyMCE.hrElement.getAttribute('width') : "";
                    noshade = tinyMCE.hrElement.getAttribute('noshade') ? tinyMCE.hrElement.getAttribute('noshade') : "";
                }
                tinyMCE.openWindow(template, {editor_id : editor_id, size : size, width : width, noshade : noshade, mceDo : 'update'});
            } else {
                if (tinyMCE.isMSIE) {
                    tinyMCE.execInstanceCommand(editor_id, 'mceInsertContent', false,'<hr />');
                } else {
                    tinyMCE.openWindow(template, {editor_id : editor_id, size : size, width : width, noshade : noshade, mceDo : 'insert'});
                }
            }
                    
       return true;
   }
   // Pass to next handler in chain
   return false;
}

function TinyMCE_advhr_handleNodeChange(editor_id, node, undo_index, undo_levels, visual_aid, any_selection) {
	tinyMCE.switchClassSticky(editor_id + '_advhr', 'mceButtonNormal');

	if (node == null)
		return;

	do {
		if (node.nodeName.toLowerCase() == "hr")
			tinyMCE.switchClassSticky(editor_id + '_advhr', 'mceButtonSelected');
	} while ((node = node.parentNode));

	return true;
}