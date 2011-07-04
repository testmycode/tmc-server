package mystring;

import org.junit.Test;
import static org.junit.Assert.*;
import testrunner.Exercise;

public class MyStringTest {

    // OhJa viikko 1, tehtävä 2. Poista testit kommenteista yksi kerrallaan
    // älä muuta testejä, tehtävä on ratkaistu kun kaikki testit menevät läpi

    /*
     *  tehtävä 2.1
     */

    @Test
    @Exercise("2.1")
    public void merkkijonojenPituusOikein() {
        MyString merkkijono1 = new MyString("koe");
        MyString merkkijono2 = new MyString("pitempi merkkijono");
        assertEquals("koe".length(), merkkijono1.length() );
        assertEquals("pitempi merkkijono".length(), merkkijono2.length() );
    }

    @Test
    @Exercise("2.1")
    public void erittainPitkanMerkkijonojenPituusOikein() {
        String pitkaString = "public void insert(int offset, char c) lisää MyString-merkkijonoon " +
                "merkin annettuun kohtaan; offset on se indeksi, jonka kohtaan merkki lisätään. " +
                "Tuolloin siis merkkijonon loppuosaa joudutaan siirtämään yhtä pykälää edemmäksi. " +
                "Sallitut lisäyskohdat ovat siis 0–pituus ellei mennä mjono-taulukon omasta ylärjasta " +
                "yli. Virheellinen indeksointi aiheuttaa poikkeuksen, jonka voi heittää vaikkapa " +
                "lauseella";
        MyString merkkijono = new MyString(pitkaString);

        assertEquals(MyString.MAKSIMIPITUUS, merkkijono.length() );
    }

 //   @Test
 //   public void sisainenTaulukkoOikeanKokoinen() throws Exception  {
 //       assertTrue("MyString-luokan sisäiselle taulukolle varattu väärä määrä tilaa",
 //               testaaTaulukonKoko() );
 //   }

    /*
     *  tehtävä 2.2
     */

    @Test
    @Exercise("2.4")
    public void konstruktorinKuormitus() {
        MyString merkkijono = new MyString();

        assertEquals( 0, merkkijono.length() );
    }

    @Test
    @Exercise("2.5")
    public void kirjaintenOttaminen() {
        String mj = "pitempi merkkijono";
        MyString merkkijono = new MyString(mj);

        for (int i = 0; i < mj.length(); i++) {
            assertEquals( mj.charAt(i), merkkijono.charAt(i) );
        }
    }

    @Test
    @Exercise("2.6")
    public void olemattomienKirjaintenOttaminenEiOnnistu() {
        MyString merkkijono = new MyString("pitempi merkkijono");

        try {
            merkkijono.charAt(100);
            fail();
        } catch (IllegalArgumentException e) {
            assertEquals("charAt-operaatiossa",e.getMessage());
        }
    }

    @Test
    @Exercise("2.5")
    public void toStringToimii() {
        MyString merkkijono = new MyString("pitempi merkkijono");

        assertEquals("pitempi merkkijono", merkkijono.toString());
    }

//    @Test
//    public void uudenMerkinLisaysKeskelle() {
//        String mj = "koe";
//        MyString merkkijono = new MyString(mj);
//
//        merkkijono.insert(2,'n');
//
//        assertEquals("kone", merkkijono.toString());
//    }
//
//    @Test
//    public void uudenMerkinLisaysAlkuunJaLopuun() {
//        String mj = "koe";
//        MyString merkkijono = new MyString(mj);
//
//        merkkijono.insert(3,'x');
//
//        assertEquals("koex", merkkijono.toString());
//
//        merkkijono.insert(0,'z');
//
//        assertEquals("zkoex", merkkijono.toString());
//    }
//
//    @Test
//    public void lisaysVaaraanPaikkaanEiOnnistuEiOnnistu() {
//        MyString merkkijono = new MyString("pitempi merkkijono");
//
//        try {
//            merkkijono.insert(25, 'x');
//            fail();
//        } catch (IllegalArgumentException e) {
//            assertEquals("insert-operaatiossa",e.getMessage());
//        }
//    }
//
//    @Test
//    public void uudenMerkinLisaysKasvattaaPituutta() {
//        String mj = "koe";
//        MyString merkkijono = new MyString(mj);
//
//        merkkijono.insert(2,'n');
//
//        assertEquals("kone".length(), merkkijono.length());
//    }
//
//    /*
//     *  tehtävä 2.3
//     */
//
//    @Test
//    public void kopionLuonti() {
//        String mj = "koe";
//        MyString merkkijono = new MyString(mj);
//        MyString merkkijono2 = new MyString(merkkijono);
//
//        assertEquals(merkkijono.toString(), merkkijono2.toString());
//    }
//
//    @Test
//    public void kopioOnAito() {
//        String mj = "koe";
//        MyString merkkijono = new MyString(mj);
//        MyString merkkijono2 = new MyString(merkkijono);
//
//        merkkijono2.insert(0, 'x');
//
//        assertEquals("koe", merkkijono.toString());
//    }
//
//    @Test
//    public void merkinKorvaaminen() {
//        String mj = "pitempi merkkijono";
//        MyString merkkijono = new MyString(mj);
//
//        merkkijono.replace('m','x');
//
//        assertEquals("pitempi merkkijono".replace('m', 'x'), merkkijono.toString());
//    }
//
//    @Test
//    public void poistoVaarastaPaikastaEiOnnistuEiOnnistu() {
//        MyString merkkijono = new MyString("pitempi merkkijono");
//
//        try {
//            merkkijono.deleteCharAt(25);
//            fail();
//        } catch (IllegalArgumentException e) {
//            assertEquals("deleteCharAt-operaatiossa",e.getMessage());
//        }
//    }
//
//    @Test
//    public void merkinPoistoAlusta() {
//        String mj = "kone";
//        MyString merkkijono = new MyString(mj);
//
//        merkkijono.deleteCharAt(0);
//
//        assertEquals("one", merkkijono.toString());
//    }
//
//    @Test
//    public void merkinPoistoKeskelta() {
//        String mj = "kone";
//        MyString merkkijono = new MyString(mj);
//
//        merkkijono.deleteCharAt(2);
//
//        assertEquals("koe", merkkijono.toString());
//    }
//
//    @Test
//    public void merkinPoistoLopusta() {
//        String mj = "kone";
//        MyString merkkijono = new MyString(mj);
//
//        merkkijono.deleteCharAt(3);
//
//        assertEquals("kon", merkkijono.toString());
//    }
//
//    @Test
//    public void merkinPoistoVahentaaPituutta() {
//        String mj = "kone";
//        MyString merkkijono = new MyString(mj);
//
//        merkkijono.deleteCharAt(0);
//
//        assertEquals("one".length(), merkkijono.length());
//    }
//
//    /*
//     *  tehtävä 2.4
//     */
//
//    @Test
//    public void aakkosVertailuToimii() {
//        MyString merkkijono1 = new MyString("eka");
//        MyString merkkijono2 = new MyString("toka");
//        MyString merkkijono3 = new MyString("eka");
//
//        assertTrue( merkkijono1.compareTo(merkkijono2)<0 );
//        assertTrue( merkkijono2.compareTo(merkkijono1)>0 );
//        assertTrue( merkkijono1.compareTo(merkkijono3)==0 );
//    }
//
//    @Test
//    public void sisällönSamuusvertailuToimii() {
//        MyString merkkijono1 = new MyString("eka");
//        MyString merkkijono2 = new MyString("toka");
//        MyString merkkijono3 = new MyString("eka");
//
//        assertTrue( merkkijono1.equals(merkkijono3) );
//        assertFalse( merkkijono2.equals(merkkijono1) );
//    }
//
//    @Test
//    public void loytaaIndeksin() {
//        MyString merkkijono = new MyString("pitempi merkkijono");
//
//        assertEquals("pitempi merkkijono".indexOf('k'), merkkijono.indexOf('k'));
//    }
//
//    @Test
//    public void josMerkkiaEiOleToimiiIndeksinEtsintaSilti() {
//        MyString merkkijono = new MyString("pitempi merkkijono");
//
//        assertEquals("pitempi merkkijono".indexOf('x'), merkkijono.indexOf('x'));
//    }
//
//    @Test
//    public void loytaaAlimerkkijononIndeksin() {
//        MyString merkkijono1 = new MyString("pitempi merkkijono");
//        MyString merkkijono2 = new MyString("merkki");
//
//        assertEquals("pitempi merkkijono".indexOf("merkki"), merkkijono1.indexOf(merkkijono2));
//    }
//
//    @Test
//    public void toimiiJosAlimerkkijonoEiLoydy() {
//        MyString merkkijono1 = new MyString("pitempi merkkijono");
//        MyString merkkijono2 = new MyString("olutpullo");
//
//        assertEquals("pitempi merkkijono".indexOf("olutpullo"), merkkijono1.indexOf(merkkijono2));
//    }
//
//    /**************************************************************************************
//     *
//     *  apumetodi, sotkuista koodia
//     *
//     */
//
//    private boolean testaaTaulukonKoko() throws Exception {
//        MyString merkkijono = new MyString("koe");
//
//        Field fields[] = merkkijono.getClass().getDeclaredFields();
//        for (int i = 0; i < fields.length; i++) {
//            if ( fields[i].getName().equals("mjono") ){
//                fields[i].setAccessible(true);
//                if ( ((char [])fields[i].get(merkkijono)).length != MyString.MAKSIMIPITUUS)
//                    return false;
//            }
//        }
//
//        return true;
//    }
}
