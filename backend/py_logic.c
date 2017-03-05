#include <Python.h>
#include "game_logic.h"
#include <stdlib.h>

_Bool initialized = 0;
PyObject *module = NULL;

void py_init(void) {
	if(!initialized) {
		Py_Initialize();
		PyObject *module_name = PyUnicode_FromString("bship_logic");
		PyRun_SimpleString("import sys\nsys.path.append('.')");
		module = PyImport_Import(module_name);
		Py_DECREF(module_name);
		if (module == NULL) {
			if (PyErr_Occurred()) {
				PyErr_Print();
				fprintf(stderr, "bship_logic import failed\n");
			}
			exit(1);
		}
		initialized = 1;
	}
}


new_game_result bship_logic_new_game(void){
	new_game_result r;
	py_init();
	PyObject *func = PyObject_GetAttrString(module, "new_game");
	if ((func == NULL) || !PyCallable_Check(func)) {
		fprintf(stderr, "bship_logic.new_game not usable\n");
		exit(1);
	}
	PyObject *ret = PyObject_CallObject(func, NULL);
	Py_DECREF(func);
	if (ret == NULL) {
		fprintf(stderr, "bship_logic.new_game failed\n");
		exit(1);
	}
	PyArg_ParseTuple(ret, "ii", &r.pid, &r.gid);
	return r;
}

plyr_id bship_logic_join_game(game_id gid) {
	py_init();
	PyObject *func = PyObject_GetAttrString(module, "join_game");
	if ((func == NULL) || !PyCallable_Check(func)) {
		fprintf(stderr, "bship_logic.join_game not usable\n");
		exit(1);
	}
	PyObject *args = Py_BuildValue("(i)", gid);
	PyObject *ret = PyObject_CallObject(func, args);
	Py_DECREF(func);
	if (ret == NULL) {
		fprintf(stderr, "bship_logic.join_game failed\n");
		// If this fails, it means I didn't catch an exception in the
		// Python code. This should never happen: I really do try to
		// handle all exceptions in Python.
		return -10;
	}
	long res = PyLong_AsLong(ret);
	Py_DECREF(ret);
	return (int)res;
}

int bship_logic_submit_grid(plyr_id pid, grid _g) {
	py_init();
	PyObject *func = PyObject_GetAttrString(module, "submit_grid");
	if ((func == NULL) || !PyCallable_Check(func)) {
		fprintf(stderr, "bship_logic.submit_grid not usable\n");
		exit(1);
	}
	PyObject *args = PyTuple_New(2);
	PyObject *py_pid = Py_BuildValue("i", pid);
	PyTuple_SetItem(args, 0, py_pid); // py_gid ref stolen

	// We want to build a 5-length list of 4-length lists here
	PyObject *py_grid = PyList_New(5);
	int i = 0;
	for (i = 0; i <= 4; i++) {
		PyObject *ship_list = Py_BuildValue("[i,i,i,i]",
											_g.s[i].x1,
											_g.s[i].y1,
											_g.s[i].x2,
											_g.s[i].y2);
		PyList_SetItem(py_grid, i, ship_list); // ship_list ref stolen
	}
	PyTuple_SetItem(args, 1, py_grid);
	PyObject *ret = PyObject_CallObject(func, args);
	Py_DECREF(func);
	if (ret == NULL) {
		fprintf(stderr, "bship_logic.submit_grid failed\n");
		return ERR_INVALID_GRID;
	}
	long result = PyLong_AsLong(ret);
	Py_DECREF(ret);
	return result;
}

int bship_logic_bomb_position(plyr_id pid, int x, int y) {
	py_init();
	PyObject *func = PyObject_GetAttrString(module, "bomb_position");
	if ((func == NULL) || !PyCallable_Check(func)) {
		fprintf(stderr, "bship_logic.bomb_position not usable\n");
		exit(1);
	}
	PyObject *args = Py_BuildValue("(iii)", pid, x, y);
	PyObject *ret = PyObject_CallObject(func, args);
	Py_DECREF(func);
	if (ret == NULL) {
		fprintf(stderr, "bship_logic.bomb_position failed\n");
		return ERR_INVALID_BOMB_TARGET;
	}
	long result = PyLong_AsLong(ret);
	Py_DECREF(ret);
	return result;
}

get_game_end_result bship_logic_get_game_end(plyr_id pid) {
	py_init();
	get_game_end_result r;
	PyObject *func = PyObject_GetAttrString(module, "get_game_end");
	if ((func == NULL) || !PyCallable_Check(func)) {
		fprintf(stderr, "bship_logic.get_game_end not usable\n");
		exit(1);
	}
	PyObject *args = Py_BuildValue("(i)", pid);
	PyObject *ret = PyObject_CallObject(func, args);
	Py_DECREF(func);
	if (ret == NULL) {
		fprintf(stderr, "bship_logic.get_game_end failed\n");
		r.game_over = 0;
		r.won = 0;
		return r;
	}
	PyObject *py_grid = PyTuple_GetItem(ret, 0); // 5-length list of 4-length lists
	PyObject *py_gameover = PyTuple_GetItem(ret, 1); // int
	PyObject *py_won = PyTuple_GetItem(ret, 2); // int

	// convert the py_grid to a real grid
	ship newships[5];
	int i = 0;
	for (i = 0; i <= 4; i++) {
		PyObject *c = PyList_GetItem(py_grid, i);
		newships[i].x1 = PyLong_AsLong(PyList_GetItem(c, 0));
		newships[i].y1 = PyLong_AsLong(PyList_GetItem(c, 1));
		newships[i].x2 = PyLong_AsLong(PyList_GetItem(c, 2));
		newships[i].y2 = PyLong_AsLong(PyList_GetItem(c, 3));
		Py_DECREF(c);
	}
	grid newgrid;
	memcpy(newgrid.s, newships, sizeof(newgrid.s));

	r.grid = newgrid;
	r.game_over = (PyLong_AsLong(py_gameover) == 1);
	r.won = (PyLong_AsLong(py_won) == 1);
	Py_DECREF(ret);
	return r;
}

plyr_state bship_logic_get_plyr_state(plyr_id pid) {
	py_init();
	PyObject *func = PyObject_GetAttrString(module, "get_plyr_state");
	if ((func == NULL) || !PyCallable_Check(func)) {
		fprintf(stderr, "bship_logic.get_plyr_state not usable\n");
		exit(1);
	}
	PyObject *args = Py_BuildValue("(i)", pid);
	PyObject *ret = PyObject_CallObject(func, args);
	Py_DECREF(func);
	if (ret == NULL) {
		fprintf(stderr, "bship_logic.get_plyr_state failed\n");
		return -10;
	}
	long res = PyLong_AsLong(ret);
	Py_DECREF(ret);
	return (int)res;
}

int bship_logic_request_notify(plyr_id pid, plyr_state state, void *user) {
	py_init();
	PyObject *func = PyObject_GetAttrString(module, "request_notify");
	if ((func == NULL) || !PyCallable_Check(func)) {
		fprintf(stderr, "bship_logic.request_notify not usable\n");
		exit(1);
	}
	PyObject *args = PyTuple_New(3);
	PyTuple_SetValue(0, Py_BuildValue("i", pid));
	PyTuple_SetValue(1, Py_BuildValue("i", state));
	// Note: I use a PyCapsule here instead of casting user to long
	// long or something since it is technically possible that the
	// pointer won't fit in a long long.
	PyTuple_SetValue(2, PyCapsule_New(user, "user data", NULL));
	PyObject *ret = PyObject_CallObject(func, args);
	Py_DECREF(func);
	if (ret == NULL) {
		fprintf(stderr, "bship_logic.request_notify failed\n");
		return -10;
	}
	long res = PyLong_AsLong(ret);
	Py_DECREF(ret);
	return (int)res;
}


