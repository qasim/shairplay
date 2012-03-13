#include <stdlib.h>

#include "dnssd.h"
#include "dnssdint.h"
#include "global.h"
#include "utils.h"

#import <Foundation/Foundation.h>

#define MAX_SERVNAME 256

struct dnssd_s {
	char hwaddr[MAX_HWADDR_LEN];
	int hwaddrlen;

	NSNetService *raopService;
	NSNetService *airplayService;
};

dnssd_t *
dnssd_init(const char *hwaddr, int hwaddrlen, int *error)
{
	dnssd_t *dnssd;

	if (error) *error = DNSSD_ERROR_NOERROR;
	if (hwaddrlen > MAX_HWADDR_LEN) {
		if (error) *error = DNSSD_ERROR_HWADDRLEN;
		return NULL;
	}

	dnssd = calloc(1, sizeof(dnssd_t));
	if (!dnssd) {
		if (error) *error = DNSSD_ERROR_OUTOFMEM;
		return NULL;
	}
	memcpy(dnssd->hwaddr, hwaddr, hwaddrlen);
	dnssd->hwaddrlen = hwaddrlen;

	return dnssd;
}

void
dnssd_destroy(dnssd_t *dnssd)
{
	free(dnssd);
}

int
dnssd_register_raop(dnssd_t *dnssd, const char *name, unsigned short port)
{
	char hwaddrstr[MAX_SERVNAME];
	NSString *serviceString;
	NSMutableDictionary *txtDict;
	NSData *txtData;
	int ret;

	assert(dnssd);

	if (dnssd->raopService != nil) {
		return -1;
	}

	/* Convert the hardware address to string */
	ret = utils_hwaddr_raop(hwaddrstr, sizeof(hwaddrstr), dnssd->hwaddr, dnssd->hwaddrlen);
	if (ret < 0) {
		return -2;
	}
	serviceString = [NSString stringWithFormat:@"%s@%s", hwaddrstr, name];

	txtDict = [NSMutableDictionary dictionaryWithCapacity:0];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_TXTVERS] forKey:@"txtvers"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_CH] forKey:@"ch"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_CN] forKey:@"cn"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_ET] forKey:@"et"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_SV] forKey:@"sv"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_DA] forKey:@"da"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_SR] forKey:@"sr"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_SS] forKey:@"ss"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_PW] forKey:@"pw"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_VN] forKey:@"vn"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_TP] forKey:@"tp"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_MD] forKey:@"md"];
	[txtDict setValue:[NSString stringWithUTF8String:GLOBAL_VERSION] forKey:@"vs"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_AM] forKey:@"am"];
	[txtDict setValue:[NSString stringWithUTF8String:RAOP_SF] forKey:@"sf"];
	txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];

	/* Create the service and publish it */
	dnssd->raopService = [[NSNetService alloc] initWithDomain:@""
	                                           type:@"_raop._tcp"
	                                           name:serviceString
	                                           port:port];
	[dnssd->raopService setTXTRecordData:txtData];
	[dnssd->raopService publish];
	return 1;
}

int
dnssd_register_airplay(dnssd_t *dnssd, const char *name, unsigned short port)
{
	NSMutableDictionary *txtDict;
	NSData *txtData;
	char deviceid[3*MAX_HWADDR_LEN];
	char features[16];
	int ret;

	assert(dnssd);

	if (dnssd->airplayService != nil) {
		return -1;
	}

	/* Convert hardware address to string */
	ret = utils_hwaddr_airplay(deviceid, sizeof(deviceid), dnssd->hwaddr, dnssd->hwaddrlen);
	if (ret < 0) {
		return -2;
	}

	memset(features, 0, sizeof(features));
	snprintf(features, sizeof(features)-1, "0x%x", GLOBAL_FEATURES);

	txtDict = [NSMutableDictionary dictionaryWithCapacity:0];
	[txtDict setValue:[NSString stringWithUTF8String:deviceid] forKey:@"deviceid"];
	[txtDict setValue:[NSString stringWithUTF8String:features] forKey:@"features"];
	[txtDict setValue:[NSString stringWithUTF8String:GLOBAL_MODEL] forKey:@"model"];
	txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];

	/* Create the service and publish it */
	dnssd->airplayService = [[NSNetService alloc] initWithDomain:@""
	                                           type:@"_airplay._tcp"
	                                           name:[NSString stringWithUTF8String:name]
	                                           port:port];
	[dnssd->airplayService setTXTRecordData:txtData];
	[dnssd->airplayService publish];
	return 1;
}

void
dnssd_unregister_raop(dnssd_t *dnssd)
{
	assert(dnssd);

	if (dnssd->raopService == nil) {
		return;
	}

	[dnssd->raopService stop];
	[dnssd->raopService release];
	dnssd->raopService = nil;
}

void
dnssd_unregister_airplay(dnssd_t *dnssd)
{
	assert(dnssd);

	if (dnssd->airplayService == nil) {
		return;
	}

	[dnssd->airplayService stop];
	[dnssd->airplayService release];
	dnssd->airplayService = nil;
}