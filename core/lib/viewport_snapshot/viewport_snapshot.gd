class_name ViewportSnapshot
extends RefCounted

## Renders a hidden `SubViewport` (update mode «disabled» in the scene) once and saves it as PNG.
## Call after filling the viewport's content: waits a frame so containers / labels settle first.
## Dummy renderer (headless) or a failed readback → error code, nothing written.


static func save_png(viewport: SubViewport, path: String) -> Error:
	var tree := viewport.get_tree()
	if tree == null:
		return ERR_UNCONFIGURED
	await tree.process_frame
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return ERR_CANT_CREATE
	var dir_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		return dir_error
	return image.save_png(path)
