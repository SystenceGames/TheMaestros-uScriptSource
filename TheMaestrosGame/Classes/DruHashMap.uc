/**
 * A very simple statically sized, int->Object hash map
 * 
 **/

class DruHashMap extends Object;

var private int table_size;
var private int count; // populated size
var private Array<HashMapEntry> table;

/**
 * Create a hashmap. Since this does not resize
 * automatically, the programmer must pick a reasonable
 * starting size
 **/
public static function DruHashMap Create(int size)
{
	local DruHashMap area;

	area = new class'DruHashMap';
	// Setup the size
	area.table.Add(size);
	area.table_size=size;

	return area;
}

/**
 * Check to see if this hashtable
 * contains an item.
 * 
 * This is just as expensive as Get()
 **/
public function bool Contains(const int key)
{
	return GetByIntKey(key)!=None;
}

/**
 * Get an item from the hashtable by INTEGER key
 **/
public function Object GetByIntKey(const int key)
{
	local HashMapEntry entry;
	local int hash;
	local int loopCheck;

	if(key==-1)
		return None;
	hash = (key % TABLE_SIZE);

	// sanity check
	if( table[hash] == none ) return None;

	// Go down the chain
	entry = table[hash];

	loopCheck = 0;

	while( entry != none )
	{
		if( entry.key == key ) return entry.value;
		entry = entry.next;

		// There was a runaway loop here. So I'm adding this gross check to prevent crashes.
		if( ++loopCheck >= 20 )
		{
			`warn("Likely a runaway loop in DruHashMap::Get() Count:" @ count);
			return None;
		}
	}
	return None;
}

/**
 * Place an object in the hashtable 
 * with the provided INTEGER key
 **/
public function PutByIntKey(const int key, const out Object value)
{
	local int hash;
	local HashMapEntry entry;
	local HashMapEntry current;

	entry       = new class'HashMapEntry';
	entry.key   = key;
	entry.value = value;
	entry.next  = none;

	hash = (key % TABLE_SIZE);

	if( table[hash] == none )
	{
		table[hash] = entry;
	}
	else
	{
		// Go down the chain
		current = table[hash];

		while( current.next != none )
			current = current.next;
		current.next = entry;
	}
	count++;
}

public function RemoveByIntKey(int key)
{
	local HashMapEntry prev;
	local HashMapEntry entry;
	local int hash;	
	
	prev = none;

	hash = (key % TABLE_SIZE);

	// sanity check, its already gone
	if( table[hash] == none ) return;

	// Setting up to go down the chain
	entry = table[hash];

	// Go down the chain
	while( entry != none )
	{
		if( entry.key == key )
		{
			if( prev == none )
				table[hash] = entry.next;   // Pop the top of the chain, replacing with next
			else
				prev.next = entry.next;     // vaporize the current entry
			count--;
			return;
		}
		prev  = entry;
		entry = entry.next;
	}

	return; // Dru TODO: deleteme?
}

/**
 * Return the hashtable 
 * for iteration purposes.
 **/
public function Array<HashMapEntry> getTable() {
	return table;
}

DefaultProperties
{
	table_size=128
}
