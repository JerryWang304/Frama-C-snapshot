(**************************************************************************)
(*                                                                        *)
(*  This file is part of Frama-C.                                         *)
(*                                                                        *)
(*  Copyright (C) 2007-2010                                               *)
(*    CEA (Commissariat � l'�nergie atomique et aux �nergies              *)
(*         alternatives)                                                  *)
(*                                                                        *)
(*  you can redistribute it and/or modify it under the terms of the GNU   *)
(*  Lesser General Public License as published by the Free Software       *)
(*  Foundation, version 2.1.                                              *)
(*                                                                        *)
(*  It is distributed in the hope that it will be useful,                 *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU Lesser General Public License for more details.                   *)
(*                                                                        *)
(*  See the GNU Lesser General Public License version 2.1                 *)
(*  for more details (enclosed in the file licenses/LGPLv2.1).            *)
(*                                                                        *)
(**************************************************************************)

(** The extensible GUI.
    @plugin development guide *)

open Db_types
open Cil_types

(** This is the type of source code buffers that can react to global
    selections and highlighters.
    @since Beryllium-20090901 *)
class type reactive_buffer = object
  inherit Gtk_helper.error_manager
  method buffer : GSourceView2.source_buffer
  method locs : Pretty_source.Locs.state option
  method rehighlight : unit
end

class protected_menu_factory:
  Gtk_helper.host -> GMenu.menu -> [ GMenu.menu ] GMenu.factory

(** This is the type of extension points for the GUI.
    @modify Boron-20100401 new way of handling the menu and the toolbar
    @plugin development guide *)
class type main_window_extension_points = object

  (** {3 Main Components} *)

  method toplevel : main_window_extension_points
    (** The whole GUI aka self *)

  method menu_manager: Menu_manager.menu_manager
    (** The object managing the menubar and the toolbar.
	@since Boron-20100401 *)

  method file_tree : Filetree.t
    (** The tree containing the list of files and functions *)

  method file_tree_view : GTree.view
    (** The tree view containing the list of files and functions *)

  method main_window : GWindow.window
    (** The main window *)

  method annot_window : GText.view
    (** The information pannel.
        The text is cleared whenever the selection is changed. *)

  method lower_notebook : GPack.notebook
    (** The lower notebook with messages tabs *)

  (** {4 Source viewer}  *)

  method source_viewer : GSourceView2.source_view
    (** The [GText.view] showing the AST.
	@plugin development guide *)

  method display_globals : global list -> unit
    (** Display globals in the general [source_view]. *)

  (** {4 Original source viewer}  *)

  method original_source_viewer : Source_manager.t
    (** The multi-tab source file display widget. *)

  method view_original : location -> unit
    (** Display the given [location] in the [original_source_viewer] *)

  method view_original_stmt : stmt -> location
    (** Display the given [stmt] in the [original_source_viewer] *)

  method view_original : location -> unit
    (** Display the given [location] in the [original_source_viewer] *)

  (** {3 Dialog Boxes} *)

  method launcher : unit -> unit
    (** Display the analysis configuration dialog and offer the
	opportunity to launch to the user *)

  method error :
    'a. ?parent:GWindow.window_skel -> ('a, Format.formatter, unit) format -> 'a
    (** Popup a modal dialog displaying an error message *)

  (** {3 Extension Points} *)

  method register_source_selector :
    (GMenu.menu GMenu.factory
     -> main_window_extension_points
       -> button:int -> Pretty_source.localizable -> unit) -> unit
    (** register an action to perform when button is released on a given
        localizable.
        If the button 3 is released, the first argument is popped as a
        contextual menu. *)

  method register_source_highlighter :
    (GSourceView2.source_buffer -> Pretty_source.localizable ->
       start:int -> stop:int -> unit)
    -> unit
    (** register an highlighting function to run on a given localizable
        between start and stop in the given buffer.
        Priority of [Gtext.tags] is used to decide which tag is rendered on
        top of the other. *)

  method register_panel :
    (main_window_extension_points->(string*GObj.widget*(unit-> unit) option))
    -> unit
    (** [register_panel f] registers a panel in GUI.
        [f self] returns the name of the panel to create,
        the widget containing the panel and a function to be called on
	refresh. *)

  (** {3 General features} *)

  method reset : unit -> unit
    (** Reset the GUI and its extensions to its initial state *)

  method rehighlight : unit -> unit
    (** Force to rehilight the current displayed buffer.
        Plugins should call this method whenever they have changed the states
	on which the function given to [register_source_highlighter] have been
        updated. *)

  method scroll : Pretty_source.localizable -> unit
    (** Scroll to the given localizable in the current buffer if possible. *)

  method protect :
    cancelable:bool -> ?parent:GWindow.window_skel -> (unit -> unit) -> unit
    (** Lock the GUI ; run the funtion ; catch all exceptions ; Unlock GUI
	The parent window must be set if this method is not called directly
	by the main window: it will ensure that error dialogs are transient
	for the right window.

	Set cancelable to [true] if the protected action should be cancellable
	by the user through button `Stop'. *)

  method full_protect :
    'a . cancelable:bool -> ?parent:GWindow.window_skel -> (unit -> 'a) ->
    'a option
    (** Lock the GUI ; run the funtion ; catch all exceptions ; Unlock GUI ;
        returns [f ()].
	The parent window must be set if this method is not called directly
	by the main window: it will ensure that error dialogs are transient
	for the right window.

	Set cancelable to [true] if the protected action should be cancellable
	by the user through button `Stop'. *)

  method push_info : 'a. ('a, Format.formatter, unit) format -> 'a
    (** Pretty print a temporary information in the status bar *)

  method pop_info : unit -> unit
    (** Remove last temporary information in the status bar *)

  method help_message : 'a 'b.
    (<event : GObj.event_ops ; .. > as 'a) ->
    ('b, Format.formatter, unit) format ->
    'b
    (** Help message displayed when entering the widget *)

end

class main_window : unit -> main_window_extension_points

val register_extension : (main_window_extension_points -> unit) -> unit
  (** Register an extension to the main GUI. It will be invoked at
      initialization time.
      @plugin development guide *)

val register_reset_extension : (main_window_extension_points -> unit) -> unit
  (** Register a function to be called whenever the main GUI reset method is
      called. *)

val apply_on_selected : (Pretty_source.localizable -> unit) -> unit
  (** [apply_on_selected f] applies [f] to the currently selected
      [Pretty_source.localizable]. Does nothing if nothing is selected. *)

 val reactive_buffer : main_window_extension_points ->
   ?parent_window:GWindow.window -> global list -> reactive_buffer
   (** This function creates a reactive buffer for the given list of globals.
       These buffers are cached and sensitive to selections and highlighters.
       @since Beryllium-20090901 *)

(*
Local Variables:
compile-command: "make -C ../.."
End:
*)