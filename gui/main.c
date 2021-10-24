// Thanks to https://librebay.github.io for a good guide

#include <gtk/gtk.h>

int
main(int argc, char *argv[])
{
	GtkWidget *window;
	GtkWidget *button;

	gtk_init(&argc, &argv);

	window = gtk_window_new(GTK_WINDOW_TOPLEVEL);	
	button = gtk_button_new_with_label("Hello World!");
	gtk_container_add(GTK_CONTAINER(window), button);

	gtk_widget_show(window);
	gtk_main();

	return 0;
}
