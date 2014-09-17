#include "interface/event.h"

namespace network
{
	struct PeerInfo
	{
		typedef size_t Id;

		Id id = 0;
		ss_ address;
	};

	struct Packet: public interface::Event::Private
	{
		typedef size_t Type;

		PeerInfo::Id recipient;
		Type type;
		ss_ data;

		Packet(PeerInfo::Id recipient, const Type &type, const ss_ &data):
			recipient(recipient), type(type), data(data){}
	};

	struct NewClient: public interface::Event::Private
	{
		PeerInfo info;

		NewClient(const PeerInfo &info): info(info){}
	};

	struct Interface
	{
		virtual Packet::Type packet_type(const ss_ &name) = 0;
		virtual void send(PeerInfo::Id recipient, const Packet::Type &type,
				const ss_ &data) = 0;
		virtual void send(PeerInfo::Id recipient, const ss_ &name,
				const ss_ &data) = 0;
	};

	inline struct Interface *get_interface(interface::Server *server)
	{
		interface::Module *module = server->check_module("network");
		return (network::Interface*)module->check_interface();
	}
}
