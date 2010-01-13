/* -*- Mode: Vala; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 2 -*- */
/*
 * tray.vala
 * Copyright (C) Pontus Östlund 2009 <pontus@poppa.se>
 *
 * This file is part of Roxen Application Launcher (RAL)
 * 
 * RAL is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * RAL is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with RAL.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;

namespace Roxenlauncher
{
  public class Tray : GLib.Object
  {
    Gtk.StatusIcon icon;
    Gtk.Menu       popmenu;
    string m_show = _("Click to show the application launcher");
    string m_hide = _("Click to hide the application launcher");
    string t_show = _("Show application launcher");
    string t_hide = _("Hide application launcher");    

    construct {
      try {
        Gdk.Pixbuf logo;
        string ico = get_ui_path("pixmap/roxen-logo-small.png");
        logo = new Gdk.Pixbuf.from_file(ico);
        icon = new Gtk.StatusIcon.from_pixbuf(logo);
        icon.tooltip_text = m_hide;
        icon.set_visible(false);
      }
      catch (Error e) {
        warning("Unable to load logo for tray! Cant start panel applet");
      }
    }
    
    public StatusIcon get_icon()
    {
      return icon;
    }
    
    public void hookup()
    {
      icon.popup_menu += on_trayicon_popup;
      icon.activate += set_window_visibility;
      icon.set_visible(true);
    }
    
    public void set_blinking(bool val)
    {
      icon.set_blinking(val);
    }
    
    void on_trayicon_popup(uint btn, uint time)
    {
      var visible     = win.get_window().visible;
      popmenu         = new Gtk.Menu();
      var item_quit   = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_QUIT, null);
      var img_hide    = new Gtk.Image.from_stock(Gtk.STOCK_CLOSE, 
                                                 Gtk.IconSize.MENU);
      var img_show    = new Gtk.Image.from_stock(Gtk.STOCK_OPEN, 
                                                 Gtk.IconSize.MENU);
      var item_toggle = new Gtk.ImageMenuItem.with_label(visible ? t_hide : 
                                                                   t_show);
      item_toggle.set_image(visible ? img_hide : img_show);

      Gee.ArrayList<LauncherFile> lfs = LauncherFile.get_reversed_files();

      if (lfs.size == 0) {
        var mi = new Gtk.MenuItem.with_label(_("No active files"));
        mi.sensitive = false;
        popmenu.add(mi);
      }
      else {
        foreach (LauncherFile lf in lfs) {
          Gtk.MenuItem mi = null;
          if (lf.status == LauncherFile.Statuses.DOWNLOADED ||
              lf.status == LauncherFile.Statuses.UPLOADED)
          {
            string img = lf.status == LauncherFile.Statuses.DOWNLOADED ?
                                      Gtk.STOCK_GO_DOWN : Gtk.STOCK_GO_UP;
            var imi = new Gtk.ImageMenuItem.from_stock(img, null);
            imi.set_label(lf.get_uri());
            mi = (MenuItem)imi;
          }
          else
            mi = new Gtk.MenuItem.with_label(lf.get_uri());

          mi.activate += (widget) => {
            try {
              var f = LauncherFile.find_by_uri(((Gtk.MenuItem)widget).label);
              if (f != null)
                f.download();
            }
            catch (Error e) {
              warning("Error calling download: %s", e.message);
            }
          };

          popmenu.add(mi);
        }
      }

      var finish_all = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_CLEAR, null);
      finish_all.activate += () => {
        Idle.add(() => { win.finish_all_files(); return false; });
        popmenu.popdown();
      };

      if (lfs.size == 0)
        finish_all.sensitive = false;

      item_quit.activate += win.on_window_destroy;
      item_toggle.activate += set_window_visibility;

      popmenu.add(new Gtk.SeparatorMenuItem());
      popmenu.add(finish_all);
      popmenu.add(item_toggle);
      popmenu.add(item_quit);
      popmenu.show_all();
      popmenu.popup(null, null, null, btn, time);
    }
    
    void set_window_visibility()
    {
      var v = win.get_window().visible;
      win.get_window().visible = !v;
      icon.tooltip_text = v ? m_show : m_hide;
    }
  }
}