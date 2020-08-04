/*
 *  yosys -- Yosys Open SYnthesis Suite
 *
 *  Copyright (C) 2020  The Symbiflow Authors
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#include <cassert>
#include "propagation.h"

USING_YOSYS_NAMESPACE

std::vector<RTLIL::Wire*> NaturalPropagation::FindAliasWires(
    RTLIL::Wire* wire) {
    RTLIL::Module* top_module = design_->top_module();
    assert(top_module);
    std::vector<RTLIL::Wire*> alias_wires;
    pass_->extra_args(
        std::vector<std::string>{
            top_module->name.str() + "/w:" + wire->name.str(), "%a"},
        0, design_);
    for (auto module : design_->selected_modules()) {
	for (auto wire : module->selected_wires()) {
	    alias_wires.push_back(wire);
	}
    }
    return alias_wires;
}

std::vector<RTLIL::Wire*> BufferPropagation::FindIBufWires(RTLIL::Wire* wire) {
    std::vector<RTLIL::Wire*> wires;
    auto ibuf_cell = FindSinkCell(wire, "IBUF");
    RTLIL::Wire* ibuf_wire = FindSinkWireOnPort(ibuf_cell, "O");
    if (ibuf_wire) {
	wires.push_back(ibuf_wire);
	auto ibuf_wires = FindIBufWires(ibuf_wire);
	std::copy(ibuf_wires.begin(), ibuf_wires.end(),
	          std::back_inserter(wires));
    }
    return wires;
}

RTLIL::Cell* BufferPropagation::FindSinkCell(RTLIL::Wire* wire,
                                             const std::string& type) {
    RTLIL::Cell* sink_cell = NULL;
    if (!wire) {
	return sink_cell;
    }
    RTLIL::Module* top_module = design_->top_module();
    assert(top_module);
    std::string base_selection =
        top_module->name.str() + "/w:" + wire->name.str();
    pass_->extra_args(std::vector<std::string>{base_selection, "%co:+" + type,
                                               base_selection, "%d"},
                      0, design_);
    auto selected_cells = top_module->selected_cells();
    // FIXME Handle more than one sink
    assert(selected_cells.size() <= 1);
    if (selected_cells.size() > 0) {
	sink_cell = selected_cells.at(0);
	log("Found cell: %s\n", sink_cell->name.c_str());
    }
    return sink_cell;
}

RTLIL::Wire* BufferPropagation::FindSinkWireOnPort(
    RTLIL::Cell* cell, const std::string& port_name) {
    RTLIL::Wire* sink_wire = NULL;
    if (!cell) {
	return sink_wire;
    }
    RTLIL::Module* top_module = design_->top_module();
    assert(top_module);
    std::string base_selection =
        top_module->name.str() + "/c:" + cell->name.str();
    pass_->extra_args(
        std::vector<std::string>{base_selection, "%co:+[" + port_name + "]",
                                 base_selection, "%d"},
        0, design_);
    auto selected_wires = top_module->selected_wires();
    // FIXME Handle more than one sink
    assert(selected_wires.size() <= 1);
    if (selected_wires.size() > 0) {
	sink_wire = selected_wires.at(0);
	log("Found wire: %s\n", sink_wire->name.c_str());
    }
    return sink_wire;
}
