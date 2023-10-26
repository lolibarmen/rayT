import moderngl_window as mglw
import numpy as np
import pygame as pg


class App(mglw.WindowConfig):
    window_size = 1600, 900
    resource_dir = 'programs'
    frame_n = 0

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.quad = mglw.geometry.quad_fs()
        self.program = self.load_program(vertex_shader='vertex.glsl', fragment_shader='fragment.glsl')

        with open('fbo', 'rb') as file:
            self.fbo = file.read()
            file.close()

        # uniforms
        self.write('u_resolution', self.window_size)


    def write(self, uniform_name, uniform_value):
        try: self.program[uniform_name] = uniform_value
        except KeyError: print(f'uniform {uniform_name} not used')


    def render(self, time, frame_time):
        self.frame_n += 1
        self.ctx.clear()
        self.write('u_time', time)
        self.write('u_frame_n', self.frame_n)

        texture = self.ctx.texture(size=(1600,900), components=3, data=self.fbo)
        self.write('u_texture_0', 0)
        texture.use()

        self.quad.render(self.program)
        self.fbo = self.ctx.fbo.read()
                      

    def mouse_position_event(self, x, y, dx, dy):
        pass#self.program['u_mouse'] = (x, y)


if __name__ == '__main__':
    mglw.run_window_config(App)