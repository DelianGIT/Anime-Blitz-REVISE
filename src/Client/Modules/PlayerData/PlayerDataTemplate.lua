--// TYPE
export type Data = {
	Team: "A" | "B" | "None",
	
	CharacterCategory: string?,
	UltimateCharge: number,

	Level: number,
	Experience: number,

	Moveset: {
		Name: string
	}?,

	Perks: { [string]: true }
}

return true