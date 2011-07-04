package mystring;

public class MyString {

    public static final int MAKSIMIPITUUS = 100; // pisin mahdollinen merkkijono
    // näkyy kaikkialle: MyString.MAKSIMIPITUUS
    private char[] mjono; // merkkijononon esitys char-taulukkona
    private int pituus;   // montako alkioita mjono:n alusta on käytössä

    public MyString()
    {
        this.pituus = 0;
        this.mjono = new char[MAKSIMIPITUUS];
    }

    public MyString(String s)
    {
        this();
        this.pituus = s.length();
        if (this.pituus > MAKSIMIPITUUS)
            this.pituus = MAKSIMIPITUUS;

        for (int i = 0; i < this.pituus; ++i)
            this.mjono[i] = s.charAt(i);
    }

    public int length()
    {
        return this.pituus;
    }

    public char charAt(int i)
    {
        if (i < 0 || i >= this.pituus)
            throw new IllegalArgumentException("charAt-operaatiossa");
        return this.mjono[i];
    }

    @Override
    public String toString()
    {
        return new String(this.mjono, 0, this.pituus);
    }
}
