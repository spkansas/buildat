// http://www.apache.org/licenses/LICENSE-2.0
// Copyright 2014 Perttu Ahola <celeron55@gmail.com>
#include "core/log.h"
#include "interface/module.h"
#include "interface/server.h"
#include "interface/event.h"
#include "interface/fs.h"
#include "client_file/api.h"
#include "network/api.h"
#include <cereal/archives/binary.hpp>
#include <cereal/types/string.hpp>
#include <fstream>
#include <streambuf>
#define MODULE "client_lua"

using interface::Event;

namespace client_lua {

struct Module: public interface::Module
{
	interface::Server *m_server;

	Module(interface::Server *server):
		m_server(server),
		interface::Module(MODULE)
	{
		log_d(MODULE, "client_lua construct");
	}

	~Module()
	{
		log_d(MODULE, "client_lua destruct");
	}

	void init()
	{
		log_d(MODULE, "client_lua init");
		m_server->sub_event(this, Event::t("core:start"));
		m_server->sub_event(this, Event::t("core:module_loaded"));
		m_server->sub_event(this, Event::t("core:module_unloaded"));
		m_server->sub_event(this, Event::t("network:client_connected"));
	}

	void event(const Event::Type &type, const Event::Private *p)
	{
		EVENT_VOIDN("core:start", on_start)
		EVENT_TYPEN("core:module_loaded", on_module_loaded,
				interface::ModuleLoadedEvent)
		EVENT_TYPEN("core:module_unloaded", on_module_unloaded,
				interface::ModuleUnloadedEvent)
		EVENT_TYPEN("network:client_connected", on_client_connected,
				network::NewClient)
	}

	void on_start()
	{
	}

	void on_module_loaded(const interface::ModuleLoadedEvent &event)
	{
		log_t(MODULE, "on_module_loaded(): %s", cs(event.name));
		ss_ module_name = event.name;
		ss_ module_path = m_server->get_module_path(module_name);
		ss_ client_lua_path = module_path+"/client_lua";
		auto list = interface::fs::list_directory(client_lua_path);
		if(list.empty())
			return;

		sv_<ss_> log_list;
		for(const interface::fs::Node &n : list){
			if(n.is_directory)
				continue;
			log_list.push_back(n.name);
		}
		log_i(MODULE, "client_lua: %s: %s", cs(module_name), cs(dump(log_list)));

		for(const interface::fs::Node &n : list){
			if(n.is_directory)
				continue;
			const ss_ &file_path = client_lua_path+"/"+n.name;
			const ss_ &public_file_name = module_name+"/"+n.name;
			client_file::access(m_server, [&](client_file::Interface *i){
				i->add_file_path(public_file_name, file_path);
			});
		}
	}

	void on_module_unloaded(const interface::ModuleUnloadedEvent &event)
	{
		log_v(MODULE, "on_module_unloaded(): %s", cs(event.name));
		// TODO: Tell client_file to remove files
	}

	void on_client_connected(const network::NewClient &client_connected)
	{
	}
};

extern "C" {
	BUILDAT_EXPORT void* createModule_client_lua(interface::Server *server){
		return (void*)(new Module(server));
	}
}
}
// vim: set noet ts=4 sw=4:
