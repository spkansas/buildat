// http://www.apache.org/licenses/LICENSE-2.0
// Copyright 2014 Perttu Ahola <celeron55@gmail.com>
#include "core/log.h"
#include "interface/module.h"
#include "interface/module_info.h"
#include "interface/server.h"
#include "interface/event.h"
#include "loader/api.h"
#define MODULE "__loader"

// __loader.cpp
// Minimal loader-invoker for games

using interface::Event;

namespace __loader {

struct Module: public interface::Module
{
	interface::Server *m_server;

	Module(interface::Server *server):
		interface::Module(MODULE),
		m_server(server){}

	~Module(){}

	void init()
	{
		m_server->sub_event(this, Event::t("core:load_modules"));
	}

	void event(const Event::Type &type, const Event::Private *p)
	{
		EVENT_VOIDN("core:load_modules", on_load_modules)
	}

	void on_load_modules()
	{
		interface::ModuleInfo info;
		info.name = "loader";
		info.path = m_server->get_builtin_modules_path()+"/"+info.name;

		bool ok = m_server->load_module(info);
		if(!ok){
			m_server->shutdown(1, "Error loading builtin/loader");
			return;
		}

		loader::access(m_server, [&](loader::Interface *i){
			i->activate();
		});
	}
};

extern "C" {
	BUILDAT_EXPORT void* createModule___loader(interface::Server *server){
		return (void*)(new Module(server));
	}
}
}
// vim: set noet ts=4 sw=4:
