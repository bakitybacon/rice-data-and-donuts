import javax.mail.*;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Properties;
import java.util.Scanner;


public class UpdateDatabase {
  static Record process(String emailText) {
    // Order: Selections, SID, Date, Serial
    Record record = new Record();

    String[] lines = emailText.split("\n");
    boolean inCourses = false;

    for (String line : lines) {
      line = line.replace("^\\s+","").replace("\\s+$","");
      if (inCourses) {
        if (line.matches("^\\s*$")) {
          inCourses = false;
        } else {
          record.registration += "\n" + line;
        }
      } else if (line.startsWith("Full Name:")) {
        record.fullname = line.substring("Full Name: ".length());
      } else if (line.startsWith("Email Address:")) {
        record.email = line.substring("Email Address: ".length());
      } else if (line.startsWith("Rice NetID: ")) {
        record.netID = line.substring("Rice NetID: ".length());
      } else if (line.startsWith("Rice NetID (e.g. mr66, not E000xxxx): ")) {
        record.netID = line.substring("Rice NetID (e.g. mr66, not E000xxxx): ".length());
      } else if (line.startsWith("Rice Affiliation:")) {
        record.riceAffiliation = line.substring("Rice Affiliation: ".length());
      } else if (line.startsWith("School, Department, or Program: ")) {
        record.department = line.substring("School, Department, or Program: ".length());
      } else if (line.startsWith("School, Department or Program: ")) {
        record.department = line.substring("School, Department or Program: ".length());
      } else if (line.startsWith("Course Selection:")) {
        record.registration = line.substring("Course Selection: ".length());
        if (record.registration.matches("^\\s*$")) {
          record.registration = "";
        }
        inCourses = true;
      } else if (line.startsWith("SID:")) {
        record.sid = Integer.parseInt(line.substring("SID:".length()).replaceAll("\\s",""));
      } else if (line.startsWith("Date:")) {
          record.submission = line.substring("Date: ".length());
      } else if (line.startsWith("Serial:")) {
        record.serial = Integer.parseInt(line.substring("Serial:".length()).replaceAll("\\s",""));
      }
    }

    record.registration = record.registration.replace("^\\s+","")
            .replaceAll("\\s+"," ");

    return record;
  }

  static boolean uploadRecord(Record record) {
    try {
      PrintWriter out = new PrintWriter(new File("record.txt"));
      out.println(record.serial);
      out.println(record.sid);
      out.println(record.submission);
      out.println(record.fullname);
      out.println(record.email);
      out.println(record.netID);
      out.println(record.riceAffiliation);
      out.println(record.department);
      out.println(record.registration);
      out.close();
      Process p = Runtime.getRuntime().exec("/home/shady/DataDonutsDaemon/scraper/record.py");
      p.waitFor();
      return p.exitValue() == 0;
    } catch (IOException | InterruptedException e) {
      e.printStackTrace();
      return false;
    }
  }

  public static void main(String... args) throws Exception {
    Properties props = System.getProperties();
    props.setProperty("mail.store.protocol", "imaps");
    try {
      Session session = Session.getDefaultInstance(props, null);
      Store store = session.getStore("imaps");

      Scanner in = new Scanner(new File("credentials.txt"));
      store.connect("imap.gmail.com", in.next(), in.next());
      in.close();

      Folder folder = store.getFolder("datadonuts");
      Folder outfolder = store.getFolder("datadonutsarchive");


      outfolder.open(Folder.READ_WRITE);
      folder.open(Folder.READ_WRITE);
      for (Message msg : folder.getMessages()) {
        Record record = process((String) msg.getContent());
        boolean delete = uploadRecord(record);
        if (delete) {
          folder.copyMessages(new Message[] {msg}, outfolder);
          msg.setFlag(Flags.Flag.DELETED, true);
          System.out.println("Moved " + record.email + "!");
        }
      }
      folder.close(true);
      outfolder.close(true);
    } catch (NoSuchProviderException e) {
      e.printStackTrace();
      System.exit(1);
    } catch (MessagingException e) {
      e.printStackTrace();
      System.exit(2);
    }
  }
}

class Record {
  public int serial;
  public int sid;
  public String submission;
  public String fullname;
  public String email;
  public String netID;
  public String riceAffiliation;
  public String department;
  public String registration;
}
