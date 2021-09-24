module main

import gg
import gx
import wireworld { Wireworld }
import time
import math
import json
import os

struct Settings
{
mut:
	x_resolution int = 32
	y_resolution int = 32
	res_scale int = 32
	update_rate int = 10
	fps_cap int = 60
	map string
}

struct App
{
mut:
	settings Settings
	should_update bool = true
	should_tick_once bool
	update_timer time.StopWatch
	last_update i64
	update_counter i64

	should_draw_grid bool = true

	wireworld &Wireworld
	gg &gg.Context
}

fn render(mut app App)
{
	elapsed := app.update_timer.elapsed().nanoseconds()
	delta := elapsed - app.last_update
	app.last_update = elapsed
	app.update_counter += delta

	app.gg.begin()
	// rlock app.wireworld
	// {
		app.wireworld.draw(app.gg, app.settings.res_scale, app.should_draw_grid)
	// }
	app.gg.end()

	if app.should_update
	{
		update_time := f64(time.second) / app.settings.update_rate
		n := int(app.update_counter / update_time)
		app.update_counter = i64(math.fmod(app.update_counter, update_time))
		for _ in 0..n
		{
			app.wireworld.tick()
		}
	}

	if app.should_tick_once
	{
		app.should_tick_once = false
		app.update_counter = 0
		app.wireworld.tick()
	}

	time.sleep(math.max(time.second / app.settings.fps_cap - delta, 0))

}

// fn update(shared w Wireworld)
// {
// 	for
// 	{
// 		lock w
// 		{
// 			w.tick()
// 		}
// 	}
// }

fn (mut app App) save_map()
{
	app.settings.map = app.wireworld.serialise_map()
	new_settings := json.encode_pretty(app.settings)
	
	mut f := os.open_file("./config.json", "w+") or { dump(err) return }
	defer { f.close() }
	f.write_string(new_settings) or { dump(err) return }
}

fn on_key_down(mut app App, keycode gg.KeyCode)
{
	match keycode {
		.p { app.should_update = !app.should_update }
		.g { app.should_draw_grid = !app.should_draw_grid }
		.c { app.wireworld.clear() }
		.s { app.save_map() }
		.space { app.should_tick_once = true }
		else {}
	}
}

fn on_mouse_down(mut app App, btn gg.MouseButton, x f32, y f32)
{
	xt := int(x / app.settings.res_scale)
	yt := int(y / app.settings.res_scale)
	dump([xt, yt])

	match btn {
		.left {
			app.wireworld.toggle_cell(xt, yt)
			// lock app.wireworld {  }
		}
		.right {
			app.wireworld.add_electron(xt, yt)
		}
		else {}
	}
}

fn event(e &gg.Event, mut app App)
{
	match e.typ {
		.key_down { on_key_down(mut app, e.key_code) }
		.mouse_down { on_mouse_down(mut app, e.mouse_button, e.mouse_x, e.mouse_y) }
		else {}
	}
}

fn (mut app App) parse_map() []u8
{
	if app.settings.map.len > 0
	{
		x, y, map := wireworld.deserialise_map(app.settings.map)
		app.settings.x_resolution = x
		app.settings.y_resolution = y
		return map
	}
	return []u8{len: app.settings.x_resolution * app.settings.y_resolution}
}

[console]
fn main()
{
	mut app := &App {
		gg: 0
		wireworld: 0
	}

	f := os.read_file("./config.json") or { "{}" }
	app.settings = json.decode(Settings, f)?
	map := app.parse_map()

	app.gg = gg.new_context(
		window_title: "wireworld"
		width: (app.settings.x_resolution * app.settings.res_scale)
		height: (app.settings.y_resolution * app.settings.res_scale)
		resizable: false
		frame_fn: render
		event_fn: event
		user_data: app
	)

	wireworld := wireworld.create_world(wireworld.WireworldOptions{
		map: map
		x_resolution: app.settings.x_resolution,
		y_resolution: app.settings.y_resolution,
		connection_colour: gx.dark_green
		electron_head_colour: gx.yellow
		electron_tail_colour: gx.red
	})
	app.wireworld = wireworld
	
	// lock wireworld, app.wireworld {
	// }
	
	// go update(shared wireworld)
	app.update_timer = time.new_stopwatch(time.StopWatchOptions{})
	app.gg.run()
}
