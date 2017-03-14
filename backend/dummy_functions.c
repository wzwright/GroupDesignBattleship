/* This file contains functions used by the unit tests of
 * bship_logic.so. This is needed since these symbols are not defined
 * (but are used) in bship_logic.pyx, so the Python module .so it
 * produces is not loadable as-is: we need to provide the symbols.
 */

void bship_logic_notification(int pid, int state, void *data, int success) {
	
}
