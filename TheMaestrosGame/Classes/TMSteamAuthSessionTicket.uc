class TMSteamAuthSessionTicket extends Object;

const CB_MAX_TICKET = 1024;

struct TMAuthSessionTicketData {
	var byte ticketBuffer[CB_MAX_TICKET];
	var int ticketLength;
	var int requestNumber;
	var int steamResultCode;
};

var TMAuthSessionTicketData authSessionTicketData;

function array<byte> GenerateTicketFromSessionTicketData()
{
	local int i;
	local array<byte> ticket;

	ticket.Length = self.authSessionTicketData.ticketLength;

	for (i = 0; i < self.authSessionTicketData.ticketLength; ++i) 
	{
		ticket[i] = self.authSessionTicketData.ticketBuffer[i];
	}

	return ticket;
}

DefaultProperties
{
}
