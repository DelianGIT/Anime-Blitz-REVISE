--// TYPES
export type Team = "A" | "B" | "None"

export type CharacterData = {
	Name: string,
	Category: string,
	Stats: {
		Health: number
	}
}

--// FIELDS
return {"Team", "CharacterData"}